import ceylon.file { File, Nil, Writer, Path, parsePath }
import org.matcher4cl.core{ TextFormat, TextStyle, highlighted, assertThat, MatchException, Is, Description, DescriptorEnv, DefaultDescriptorEnv }
import ceylon.collection { HashMap }
    
class HtmlTextFormat() satisfies TextFormat {
    
    shared actual void writeNewLineIndent(StringBuilder stringBuilder, Integer indentCount) {
        stringBuilder.append("<br/>");
        stringBuilder.appendNewline();
        for(Integer i in 0:indentCount) {
            stringBuilder.append("&nbsp;&nbsp;&nbsp;&nbsp;");
        }
    }
    
    value escapes = HashMap{'<' -> "&lt;", '>' -> "&gt;", '&' -> "&amp;"} ;
    shared void escape(StringBuilder stringBuilder, String text) {
        for(Character c in text) {
            if(exists t = escapes[c]) {
                stringBuilder.append(t);
            } else {
                stringBuilder.appendCharacter(c);
            }
        }
    }
    
    shared actual void writeText(StringBuilder stringBuilder, TextStyle style, String text) {
        if(highlighted == style) {
            stringBuilder.append("<span class=\"error\">");
            escape(stringBuilder, text);
            stringBuilder.append("</span>");
        } else {
            escape(stringBuilder, text);
        }
    }
}

void writeHtmlFile(Path filePath, Description description) {
    
    // -- Create HTML text
    
    if(is File loc = filePath.resource) {
        loc.delete();
    }
        
    if(is Nil loc = filePath.resource) {
        File file = loc.createFile();
        Writer writer = file.writer();
        writer.write("<html><head>
                      <style type=\"text/css\">
                            .error {background-color:#FF183e;}
                      </style>
                      </head><body>");
        writer.write("<h1>Example report</h1>");
        
        // write description
        StringBuilder sb = StringBuilder();
        DescriptorEnv descriptorEnv = DefaultDescriptorEnv();
        description.appendTo(sb, HtmlTextFormat(), 0, descriptorEnv);
        writer.write(sb.string);
        
        writer.write("</body></html>");
        
        writer.close(null);
    }
}

void htmlExample() {

    try {
        assertThat([100, 11, [13, "<Hello>"]], Is([10, 11, [12, "<World>"]]), "Demo");
        
    } catch (MatchException e){
        String? tmpPath = process.propertyValue("java.io.tmpdir");
        assert(is String tmpPath);
        writeHtmlFile(parsePath(tmpPath).childPath("testReport.html"), e.mismatchDescription);
    }
}
