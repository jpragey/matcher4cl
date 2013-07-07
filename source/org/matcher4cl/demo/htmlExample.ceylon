import ceylon.file { File, Nil, Writer, Path, parsePath }
import org.matcher4cl.core{ DescrWriter, TextStyle, highlighted, assertThat, MatchException, Is, Description, DescriptorEnv, DefaultDescriptorEnv, normalStyle, EqualsMatcher }
import ceylon.collection { HashMap }
    
class HtmlDescrWriter() satisfies DescrWriter {
    
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

void writeHtmlFileNoFootNotes(Path filePath, Description description) {
    
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
        value format = HtmlDescrWriter();
        description.appendTo(sb, format, 0, descriptorEnv);

        writer.write(sb.string);
        
        writer.write("</body></html>");
        
        writer.close(null);
    }
}


void htmlExample() {

    try {
        assertThat([100, 11, [13, "<Hello>"]], Is([10, 11, [12, "<World>"]]));
        
    } catch (MatchException e){
        String? tmpPath = process.propertyValue("java.io.tmpdir");
        assert(is String tmpPath);
        writeHtmlFile(parsePath(tmpPath).childPath("testReport.html"), e.mismatchDescription);
    }
}

void writeHtmlFile(Path filePath, Description description) {
    
    if(is File loc = filePath.resource) { // Remove existing file, if any
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
        DefaultDescriptorEnv descriptorEnv = DefaultDescriptorEnv();
        value dw = HtmlDescrWriter();
        description.appendTo(sb, dw, 0, descriptorEnv);
        
        // Write footnotes
        for(fn in descriptorEnv.footNotes()) {
            dw.writeNewLineIndent(sb, 0);
            dw.writeNewLineIndent(sb, 0);
            dw.writeText(sb, normalStyle, "Reference [``fn.reference``]:");
            dw.writeNewLineIndent(sb, 0);
            fn.description.appendTo(sb, dw, 0, descriptorEnv);
        }
        
        writer.write(sb.string);
        writer.write("</body></html>");
        writer.close(null);
    }
}

void htmlExampleWithFootNotes() {

    try {
        //assertThat([100, 11, [13, "<Hello>"]], Is([10, 11, [12, "<World>"]]));
         assertThat(parseConfigFile(), EqualsMatcher(AppConfig("param"), customDescriptor));
         
    } catch (MatchException e){
        String? tmpPath = process.propertyValue("java.io.tmpdir");
        assert(is String tmpPath);
        writeHtmlFile(parsePath(tmpPath).childPath("testReport.html"), e.mismatchDescription);
    }
}


