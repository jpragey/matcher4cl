
"Handler for a match failure.
 Typically used by assertions (eg [[assertThat]]) to print a mismatch message in some way (text in console, HTML file, etc). 
 "
see ("assertThat")
by ("Jean-Pierre Ragey")
shared interface ResultHandler {
    shared formal void failed(
        "Result of failed match."
        MatcherResult matcherResult,
        "User message, will be typically added to final message. Ignored if null."
        String? userMsg = null);
}

"Exception resulting from a mismatch. It is typically thrown by `ThrowingResultHandler`."
by ("Jean-Pierre Ragey")
shared class MatchException(
    "Description of the match failure."
    shared Description mismatchDescription,
    "Short (single line) description message, also available as `Exception` `description` property."
    shared String shortDescription,
    "Exception that caused this MatchException, or null if none." 
    Exception? cause=null
    ) extends Exception(shortDescription, cause) 
{
}

    "[[ResultHandler]] that throws a [[MatchException]] when a match fails.
     It can also print a multiline failure description.
     "
by ("Jean-Pierre Ragey")
shared class ThrowingResultHandler(
    "If true (default), [[failed]] will print multiline description, using `printer`."
    Boolean printMultilineDescr = true,
    "Function to print multiline description; defaults to [[process.writeErrorLine]]"
    void printer(String multilineDescription)  => process.writeErrorLine(multilineDescription)
) satisfies ResultHandler {
    
    StringBuilder createMessage(DescrWriter writer, Description description, String prefix, DescriptorEnv descriptorEnv, Integer indentCount = 0) {
        
        StringBuilder sb = StringBuilder();
        
        sb.append(prefix);
        description.appendTo(sb, writer, indentCount, descriptorEnv);
        
        return sb;
    }
    
    "Throws a [[MatchException]] if `matcherResult` shows a mismatch.
     If constructor `printMultilineDescr` is true, print a multiline description, using `printer`."
    shared actual void failed(MatcherResult matcherResult, String? userMsg) {

        StringBuilder prefixSb = StringBuilder();
        if(exists userMsg) {
            prefixSb.append(userMsg);
            prefixSb.append(": ");
        }
        String prefix = prefixSb.string;
        
        // -- Create short message
        if(matcherResult.failed) {
            value slTextFormat = SimpleDescrWriter {
                    multiLine = false;
                    indent = "";
                    constantIndent = " ";
            }; 
            StringBuilder shortMsg = createMessage(slTextFormat, matcherResult.matchDescription, prefix, DefaultDescriptorEnv() /*not used*/);
            
            
            if(printMultilineDescr) {
                DescrWriter textFormat = SimpleDescrWriter(true /*multiLine*/, "  "/*indent*/);
                
                // -- Multiline message, collect footnotes 
                DefaultDescriptorEnv descriptorEnv = DefaultDescriptorEnv();
                StringBuilder multilineMsg = createMessage(textFormat, matcherResult.matchDescription, prefix, descriptorEnv);
                printer(multilineMsg.string);
                
                // -- print footnotes
                for(footnode in descriptorEnv.footNotes()) {
                    StringBuilder stringBuilder = StringBuilder();
                    
                    textFormat.writeText(stringBuilder, normalStyle, "Reference [``footnode.reference``]:");
                    textFormat.writeNewLineIndent(stringBuilder, 0);
                    String refLine = stringBuilder.string;
                    
                    StringBuilder footnoteMsg = createMessage(textFormat, footnode.description, refLine, DefaultDescriptorEnv() /*not used*/, 0);
                    textFormat.writeNewLineIndent(footnoteMsg, 0);
                    
                    printer(footnoteMsg.string);
                }
            }
            
            throw MatchException(matcherResult.matchDescription, shortMsg.string);
        }
    }
}



"General-purpose assertion.
 It matches an 'actual' object against a predefined Matcher; if it failed, it let a [[ResultHandler]] react. 
"
by ("Jean-Pierre Ragey")
shared void assertThat(
    
    "The object to match."
    Object? actual, 
    
    "The matcher"
    Matcher matcher,
    
    "Resolver for values matching" 
    Matcher (Object? ) resolver = defaultResolver(),
    
    "A short message that may be included in the result, if matching failed. 
     It typically describes the object to assert."
    String? userMsg = null,

    "The [[ResultHandler]] to use if matching failed." 
    ResultHandler resultHandler = ThrowingResultHandler()
    ) 
{

    MatcherResult matcherResult = matcher.match(actual, resolver); 

    if(matcherResult.failed) {
        resultHandler.failed(matcherResult, userMsg);
    }
}

