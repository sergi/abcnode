var fs = require("fs");
var PEG = require("pegjs");

var BUILD_PARSER = "build/parser.js";

desc("This is the default task. Builds the generated ABC Parser");
task("default", function (params) {
    console.log("Attempting to build the parser from the PEG grammar...")
    fs.readFile("parser.pegjs", "utf8", function(err, data)  {
        if (err) throw err;

        var data = (PEG.buildParser(data)).toSource();

        fs.writeFileSync(BUILD_PARSER, "module.exports=" + data + ";");
        console.log("Done!\nThe parser was built at " + BUILD_PARSER);
    });
});
