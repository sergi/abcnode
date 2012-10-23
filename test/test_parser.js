var fs = require("fs");
var PEG = require("pegjs");

var parser = PEG.buildParser(fs.readFileSync("parser.pegjs", "utf8"));
var tunes = fs.readFileSync("test/tunes.txt", "utf8").split("\n\n");
var mistakes = 0;

tunes.forEach(function(p) {
    try {
        var parsed = parser.parse(p + "\n");
        console.log("\x1B[0;32m:)\x1B[0m " + parsed.header.title)
        //console.log(JSON.stringify(parsed, null, 2))
    }
    catch (error) {
        console.log("\x1B[0;31m\nSyntax Error:");
        console.log(error.message);
        console.log("line: " + error.line);
        console.log("column: " + error.column);

        var debugLine = Array(error.column).join("-") + "^";
        var debugMargin = Array(error.line.toString().length + 2).join("-");

        var i;
        var lines = p.split("\n");
        for (i = 0; i < error.line; i++)
            console.log((i + 1) + "  " + lines[i]);

        console.log(debugMargin + debugLine)
        for (i = error.line + 1; i < lines.length; i++)
            console.log(i + " " + lines[i]);

        mistakes += 1;
    }
});

process.exit(mistakes.length);

