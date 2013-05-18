
doc "Handler for a match failure."
by "Jean-Pierre Ragey"
shared interface ResultHandler {
    shared formal void failed(
        doc "Result of failed match."
        MatcherResult matcherResult,
        doc "User message, will be typically added to final message. Ignored if null."
        String? userMsg = null);
}

doc "Exception resulting from a mismatch. It is typically thrown by `ThrowingResultHandler`."
by "Jean-Pierre Ragey"
shared class MatchException(
    doc "Description of the match failure."
    shared Description mismatchDescription,
    doc "Short (single line) description message, also available as `Exception` `description` property."
    shared String shortDescription,
    doc "Exception that caused this MatchException, or null if none." 
    Exception? cause=null
    ) extends Exception(shortDescription, cause) 
{
}

doc "[[ResultHandler]] that throws a [[MatchException]] when a match fails.
     It can also print a multiline failure description.
     "
by "Jean-Pierre Ragey"
shared class ThrowingResultHandler(
    doc "If true (default), [[failed]] will print multiline description, using `printer`."
    Boolean printMultilineDescr = true,
    doc "Function to print multiline description; defaults to [[process.writeErrorLine]]"
    void printer(String multilineDescription)  => process.writeErrorLine(multilineDescription)
) satisfies ResultHandler {
    
    StringBuilder createMessage(TextFormat writer, Description description, String prefix, FootNoteCollector footNoteCollector, Integer indentCount = 0) {
        
        StringBuilder sb = StringBuilder();
        
        sb.append(prefix);
        description.appendTo(sb, writer, indentCount, footNoteCollector);
        
//        String msg = sb.string;
        return sb;
    }
    
    doc "Throws a [[MatchException]] if `matcherResult` shows a mismatch.
         If constructor `printMultilineDescr` is true, print a multiline description, using `printer`."
    shared actual void failed(MatcherResult matcherResult, String? userMsg) {

        StringBuilder prefixSb = StringBuilder();
        if(exists userMsg) {
            prefixSb.append(userMsg);
            prefixSb.append(": ");
        }
        String prefix = prefixSb.string;
        
        // -- Create short message
        if(matcherResult.failed()) {
            
            StringBuilder shortMsg = createMessage(SimpleTextFormat(false /*multiLine*/, ""/*indent*/), matcherResult.matchDescription, prefix, FootNoteCollector() /*not used*/);
            
            if(printMultilineDescr) {
                TextFormat textFormat = SimpleTextFormat(true /*multiLine*/, "  "/*indent*/);
                
                // -- Multiline message, collect footnotes 
                FootNoteCollector footNoteCollector = FootNoteCollector();
                StringBuilder multilineMsg = createMessage(textFormat, matcherResult.matchDescription, prefix, footNoteCollector);
                printer(multilineMsg.string);
                
                // -- print footnotes
                for(footnode in footNoteCollector.footNotes()) {
                    StringBuilder stringBuilder = StringBuilder();
                    
                    textFormat.writeText(stringBuilder, normalStyle, "Reference [``footnode.reference``]:");
                    textFormat.writeNewLineIndent(stringBuilder, 0 /*indentCount*/);
                    String refLine = stringBuilder.string;
                    
                    StringBuilder footnoteMsg = createMessage(textFormat, footnode.description, refLine, FootNoteCollector() /*not used*/, 1);
                    textFormat.writeNewLineIndent(footnoteMsg, 0 /*indentCount*/);
                    
                    printer(footnoteMsg.string);
                }
            }
            
            throw MatchException(matcherResult.matchDescription, shortMsg.string);
        }
    }
}



doc "General-purpose assertion.
     It matches an 'actual' object against a predefined Matcher; if it failed, it let a [[ResultHandler]] react. 
    "
by "Jean-Pierre Ragey"
shared void assertThat(
    
    doc "The object to match."
    Object? actual, 
    
    doc "The matcher"
    Matcher matcher,

    doc "A short message that may be included in the result, if matching failed. 
         It typically describes the object to assert."
    String? userMsg = null,
    
    doc "Resolver for values matching" 
    MatcherResolver matcherResolver = DefaultMatcherResolver(),

    doc "The [[ResultHandler]] to use if matching failed." 
    ResultHandler resultHandler = ThrowingResultHandler()
    ) 
{

    MatcherResult matcherResult = matcher.match(actual, matcherResolver); 

    if(matcherResult.failed()) {
        resultHandler.failed(matcherResult, userMsg);
    }
}

