{
    var defaultTime = undefined;
    var defaultMeter = undefined;

    var WHOLE   = 256,
        HALF    = 128,
        QUARTER = 64,
        _4TH    = 32,
        _16TH   = 16,
        _32TH   = 8,
        _64TH   = 4,
        _128TH  = 2;

    var durations = [_128TH, _64TH, _32TH, _16TH, _4TH, QUARTER, HALF, WHOLE];
    var isDotted = function(duration) {
        return durations.indexOf(duration) === -1;
    };

    var getDots = function(duration) {
        if (duration == 0 || !isDotted(duration))
            return 0;

        var baseNote = 0;
        var l = durations.length - 1;

        for (var i=l; i>=0; i--) {
            if (duration > durations[i]) {
                baseNote = durations[i];
                break;
            }
        }

        if (baseNote == 0)
            throw new Error("Duration out of range")

        return {
            duration: baseNote,
            dots: 1 + getDots(duration - baseNote)
        }
    }

    var createTimeSignature = function(result) {
        if (isDotted(result)) {
            return getDots(result);
        } else {
            return {
                duration: result,
                dots: 0
            }
        }
    };
}

start
 = header:header song:song EOF { return { header: header, song:song } }

// Header definition and fields
header
 = refnum:reference_number? title:title+ pairs:(other_fields _)* k:(key _) {
    var p = {
        refnum: refnum || 1, // Fallback to 1 for songs that don't include one
        title:  title[0],
        key:    k[0]
    }
    for (i = 0; i < pairs.length; i++) {
        p[pairs[i][0][0]] = pairs[i][0][1];
    }
    return p;
}

reference_number
 = 'X:' _? value:integer _ { return value }

title
 = 'T:' _? value:string _ { return value }

other_fields
 = f:("A:" / "B:" / "C:" / "D:" / "G:" / "H:" / "N:" / "O:" / "R:" / "S:" / "Z:") _ value:string {
     var fields = {
         "A:": "area",
         "B:": "book",
         "C:": "composer",
         "D:": "discography",
         "G:": "group",
         "H:": "history",
         "N:": "notes",
         "O:": "origin",
         "R:": "rythm",
         "S:": "source",
         "Z:": "t_note"
     };
     return [fields[f] || "", value];
 }
 /
 "L:" _ n:note_length_strict {
     defaultTime = WHOLE * eval(n);
     return ["note_length", defaultTime];
 }
 /
 "M:" _ m:meter {
     defaultMeter = WHOLE * (eval(m) < 0.75 ? 0.0625 : 0.125);
     return ["meter", defaultMeter];
 }
 /
 "P:" _ p:parts {
    return p;
 }
 /
 "Q:" _ t:tempo {
    return t;
 }

tempo = integer+ / ("C" note_length? "=" integer+) / (note_length_strict "=" integer+)
meter = "C" / "C|" / meter_fraction
meter_fraction     = l:(integer+ "/" integer+) { return l.join("") }
note_length_strict = l:(integer+ "/" integer+) { return l.join("") }
note_length = (integer+)? ("/" (integer+))?
parts = part_spec+
part_spec = (part / ( "(" part_spec+ ")" ) ) integer+
part = "A" / "B" / "C" / "D" / "E" / "F" / "G" / "H" / "I" / "J" / "K" / "L" / "M" / "N" / "O" / "P" / "Q" / "R" / "S" / "T" / "U" / "V" / "X" / "Y" / "Z"

/* ---------------------------- Key Signature -------------------------------*/

key     = "K:" _ k:key_def _ { return k }
key_def = key_spec / "HP" / "Hp"

key_spec = k:keynote m:mode_spec? g:(" " global_accidental)* {
    if (m)
        k.mode = m;
    return k;
}

keynote = bn:basenote k:key_accidental? {
    return {
        baseNote: bn,
        accidental: k
    }
}

key_accidental  = "#" / "b"
mode_spec       = " "? m:mode extratext? { return m }
mode            = mode_minor / mode_major / mode_lydian / mode_ionian / mode_mixolydian / mode_dorian / mode_aeolian / mode_phrygian / mode_locrian
extratext       = alpha*
global_accidental = accidental basenote

mode_minor      = chars:(("m"/"M") (("i"/"I") ("n"/"N"))? ) { return chars.join("") }
mode_major      = chars:(("m"/"M") ("a"/"A") ("j"/"J")) { return chars.join("") }
mode_lydian     = chars:(("l"/"L") ("y"/"Y") ("d"/"D")) { return chars.join("") }
mode_ionian     = chars:(("i"/"I") ("o"/"O") ("n"/"N")) { return chars.join("") }
mode_mixolydian = chars:(("m"/"M") ("i"/"I") ("x"/"X")) { return chars.join("") }
mode_dorian     = chars:(("d"/"D") ("o"/"O") ("r"/"R")) { return chars.join("") }
mode_aeolian    = chars:(("a"/"A") ("e"/"E") ("o"/"O")) { return chars.join("") }
mode_phrygian   = chars:(("p"/"P") ("h"/"H") ("r"/"R")) { return chars.join("") }
mode_locrian    = chars:(("l"/"L") ("o"/"O") ("c"/"C")) { return chars.join("") }

/*-------------------------------- Song -------------------------------------*/

song
 = stave+ _

stave
 = measures:measure+ _ { return measures; }

measure
 = _ bar? notes:(note_element / tuplet)+ _ bar:(bar / nth_repeat) nth_repeat? ("\\" nl)? {

    var finalNotes = [];
    var counter    = 0;
    var beams      = [[]];
    var len = notes.length;

    for (var n = 0; n<len; n++) {
        var note        = notes[n];
        var lastBeam    = beams[beams.length - 1];
        var lastBeamLen = lastBeam.length;

        if (note.note === "rest") {
            // If the last beam contains only one note there is really no need
            // for beaming, so I delete the 'beam' property from that lone note
            // and then lastBeam is emptied.
            // In case the last beam contains more notes, an empty array is
            // pushed in beams to break the beaming. The counter is increased
            // so the next generated beam is a new one.
            if (lastBeamLen === 1) {
                lastBeam[0].beam = null;
                lastBeam.pop();
            }
            else if (lastBeamLen > 1) { beams.push([]); }

            counter = counter + 1;
            finalNotes.push([note]);
            continue;
        }

        if (len > 1) {
            if (note.duration < QUARTER &&
                !((n === len-1) && !lastBeamLen)) {
                    lastBeam.push(note);
                    note.beam = counter;
            } else if (note.duration >= QUARTER) {
                if (lastBeamLen === 1) {
                    lastBeam[0].beam = null;
                    lastBeam.pop();
                } else if (lastBeamLen > 1) {
                    counter++;
                    beams.push([]);
                }
            }
        }

        if (!Array.isArray(note))
            note = [note];

        finalNotes.push(note);
    }
    var mObj = { bar: bar[0], chords: [] };

    // For each note/chord we create a chord object that contains a notes array
    // with the proper note/chord, and attach it to the chords that the measure
    // will contain.
    finalNotes.forEach(function(n) { mObj.chords.push({ notes: n }); });

    return mObj;
}

note_element = n:note_stem broken_rhythm? _? { return n }
note_stem
    = gc:guitar_chord? gn:grace_notes? gracings* n:(note / chord) {
        if (gc)
            n.guitar_chord = gc;
        if (gn)
            n.grace_notes  = gn;

        return n;
    }

chord = "[" n:note+ "]" { return n }

note = n:note_or_rest time:time_signature? _? tie:tie? {
    if (time) {
        n.duration = time.duration;
        n.dots = time.dots
    }
    else {
        n.duration = defaultTime || defaultMeter;
    }

    if (tie)
        n.tie = true;

    return n;
}
note_or_rest = n:(pitch / rest) { return n }

pitch = acc:accidental? bn:basenote o:octave? {
    var obj = {
        accidental: acc,
        note: bn + o
    }

    if (!acc)
        delete obj.accidental;

    return obj;
}

octave       = "'" / ","
basenote     = [A-G] / [a-g]
rest         = "z" { return { note: "rest" } }
tie          = "-"
gracings     = "~" / "." / "v" / "u"
grace_notes  = "{" p:pitch+ "}" { return p }
broken_rhythm = "<"+ / ">"+

tuplet = tuplet_spec n:note_element+ {
    return {
        type: "tuple",
        notes: n
    }
}

tuplet_spec = "(" integer (":" (integer) ( ":" integer? )? )?

bar
 = bars !(stringNum)

bars
 = "|]" / "||" / "[|" / "|]" / "|:" / "|" / ":|" / "::"

nth_repeat
 = "[1" / "[2" / "|1" / ":|2"

// TODO: Validate the chord with /^[A-G](b|#)?((m(aj)?|M|aug|dim|sus)([2-7]|9|13)?)?(\/[A-G](b|#)?)?$/
guitar_chord
 = '"' chord:string_no_quotes '"' { return chord }


/* ---------------- Accidentals ----------------- */

sharp
 = "^" !("^") { return "sharp" }

natural
 = "="

flat
 = "_" !("_") { return "flat" }

double_sharp
 = "^^" { return "dsharp" }

double_flat
 = "__" { return "dflat" }

accidental
 = sharp / flat / natural / double_sharp / double_flat

/* --------------------------------------------- */

middle_pairs
 =[^XKa-z]

time_signature
 =
    ts:(stringNum "/" stringNum) {
        var num    = parseInt(ts[0]) * (defaultTime || defaultMeter);
        var denom  = parseInt(ts[2]);
        var result = parseInt(num/denom);

        return createTimeSignature(result);
    }
    /
    ts:("/" cd:stringNum) {
        var result = parseInt((defaultTime || defaultMeter) / parseInt(ts[1]));
        return createTimeSignature(result);
    }
    /
    ts:stringNum  {
        return createTimeSignature(parseFloat((defaultTime || defaultMeter) * eval(ts)))
    }
    /
    ts:("/") {
        var result = parseInt((defaultTime || defaultMeter) / 2);
        return createTimeSignature(result);
    }


// Basic types
stringNum /* integers in string format */
 = digits:[0-9]+ { return digits.join(""); }

integer "integer"
 = digits:stringNum { return parseInt(digits, 10); }

string
 = chars:[A-Za-z0-9,/'"#&.=()\-\[\]: ]+ { return chars.join ? chars.join("") : chars; }

string_no_quotes
 = chars:[A-Za-z0-9,/#&.=()\-\[\]: ]+ { return chars.join ? chars.join("") : chars; }

alpha
 = chars:[a-zA-Z] {
     if (chars.join)
         return chars.join("")
     else
         return chars
}

_
 = (whitespace / comment)*

whitespace
 = [\t\v\f \u00A0\uFEFF] / Zs / nl

LineTerminator
 = [\n\r\u2028\u2029]

nl
 = "\n"
  / "\r\n"
  / "\r"
  / "\u2028" // line separator
  / "\u2029" // paragraph separator

comment
 = "%" (!nl .)*

Zs = [\u0020\u00A0\u1680\u180E\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u3000]

EOF
  = !.

