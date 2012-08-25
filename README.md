ABC notation parser for JavaScript
==================================

ABCPeg is a parser for the [ABC music notation language](http://abcnotation.com/)
for JavaScript. Still a work in progress, it implements most of ABC 1.6. The progress can be
followed in the TODO list below.

ABCPeg uses [PEGjs](http://pegjs.majda.cz/) to generate the JavaScript parser.
The resulting parser can be used from Node.js or from the browser.

Output format
-------------

ABCPeg parses from ABC format into JSON format. This is how the generated JSON
of a random tune looks:

```javascript
{
  "header": {
    "refnum": 100,
    "title": "no name",
    "key": {
      "baseNote": "G",
      "accidental": ""
    },
    "rythm": "polka",
    "discography": "Kevin Conneff: The Week before Easter",
    "t_note": "id:hn-polka-100",
    "meter": 16,
    "note_length": 32
  },
  "song": [
    [
      [
        {
          "bar": "|",
          "chords": [
            {
              "notes": [
                {
                  "note": "B",
                  "duration": 32,
                  "beam": 0
                }
              ]
            },
    ...
```

I will add more output formats and a JSON schema for this format inthe future.

This is a project that has been dormant for more than two years, and now
I release it in GitHub hoping that this will encourage me to finish it soon.

Copyright (c) 2010-2012, Sergi Mansilla (sergi.mansilla@gmail.com)
All rights reserved.
