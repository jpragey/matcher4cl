

    "Write [[Description]] parts to a `StringBuilder`.
     It manages details on writing texts, and inserting CR + indentation.
     "
by ("Jean-Pierre Ragey")
shared interface TextFormat {
        "Write a text to `stringBuilder`, managing error highlighting.
         Typically you would escape characters here if the output format needs it (html / xml)"
    shared formal void writeText(
            "Append `text` here"
        StringBuilder stringBuilder,
            "Highlighting style." 
        TextStyle textStyle,
            "The text to write." 
        String text
        ); 

        "Add a Carriage Return (or equivalent) to `stringBuilder`, and `indentCount` indentations.
         Exact behaviour is implementation-dependent (eg in HTML: add a <br/> + some HTML indentation tag).
         Doing nothing here would lead to a single-line output text.
         "
    shared formal void writeNewLineIndent(
            "Append CR + indentation here"
        StringBuilder stringBuilder,
            "Level of indentation (0 = not indented)" 
        Integer indentCount); 
}

    "Append description as simple text in a StringBuilder. Multiline is supported but optional.
     Resulting text is typically suitable for console output.
     "
by ("Jean-Pierre Ragey")
shared class SimpleTextFormat(
    "Multiline mode: if true, CR and indentation will be added by [[writeNewLineIndent]]."
    Boolean multiLine, 
    "The indentation string, also used by [[writeNewLineIndent]]"
    String indent = "    ",
    "Value prefix, for error highlighting; \"&lt;&lt;&lt;\" by default."
    String highlightStart = "<<<",
    "Value postfix, for error highlighting; \"&gt;&gt;&gt;\" by default."
    String highlightEnd = ">>>",
    ""
    String constantIndent = ""
    ) satisfies TextFormat {
    
        "If `multiLine` is true, add a CR and `indentCount` times the `indent` string. 
         If `multiLine` is false, do nothing."
    shared actual void writeNewLineIndent(StringBuilder stringBuilder, Integer indentCount) {
        if(multiLine) {
            stringBuilder.appendNewline();
            stringBuilder.append(constantIndent);
            if(indentCount > 0) {
                for(Integer i in 1..indentCount) {
                    stringBuilder.append(indent);
                }
            }
        } else {
            stringBuilder.append(constantIndent);
        }
    }
        "Append text to `stringBuilder`; if `style` is [[errorStyle]], text is surrounded by `highlightStart` and `highlightEnd`
         (a kind of ASCII art 'highlighting')." 
    shared actual void writeText(StringBuilder stringBuilder, TextStyle style, String text) {
        if(style == highlighted) {
            stringBuilder.append(highlightStart);
        }

        stringBuilder.append(text);
        
        if(style == highlighted) {
            stringBuilder.append(">>>");
        }
    }
    
}
