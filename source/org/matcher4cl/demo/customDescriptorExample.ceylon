import org.matcher4cl.core{ assertThat, DefaultMatcherResolver, Is, Descriptor, DefaultDescriptor, Matcher, OptionalMatcherResolver, ObjectMatcher, MatcherResolver, FieldAdapter, EqualsMatcher, ListMatcher, ThrowingResultHandler, FootNoteCollector, Description, StringDescription, TextStyle, normalStyle, CompoundDescription, FootNote, TreeDescription }
import ceylon.collection { HashMap }


void customDescriptorTest() {
    // Class under test
    class Complex(re, im) {
        shared Float re; 
        shared Float im;
        // Simple matching: DefaultMatcherResolver returns an EqualMatcher for unknown objects: 
        shared actual Boolean equals(Object that) {
            if(is Complex that) {
                return re == that.re && im == that.im;
            }
            return false;
        }
    }

    // Custom descriptor: customize Complex objects, otherwise delegate to DefaultDescriptor 
    object descriptor satisfies Descriptor {
        value default = DefaultDescriptor();
        shared actual String describe(Object? obj, FootNoteCollector footNoteCollector) {
            if(is Complex obj) {
                return "" + obj.re.string + " + " + obj.im.string + "i ";
            }
            return default.describe(obj, footNoteCollector);
        }
    }
    
    class MyIs(Object? expected) extends Is (expected, DefaultMatcherResolver({}, descriptor)){}
    
    assertThat(Complex(1.0, 0.1), MyIs(Complex(1.0, 0.0)));
}

// ---------------
class Error(shared String msg, shared {Error*} causes = {}) {}
class AppConfig(shared String appParam/*application configuration here*/) {}
AppConfig|Error readConfigFile(/*file path omitted for brevity*/) {
    // Fails, in this example
    return 
    Error("Can't open application", {
        Error("Error reading config file 'myapp.config'", {
            Error("Config parameter xyz not found."),
            Error("Config parameter tuv: invalid syntax.")
        })}); 
}

// -- Basic test
void poorTestConfigFile0() {    // Message is '=='org.matcher4cl.demo.AppConfig@7e1c8e60/<<<org.matcher4cl.demo.Error@1ab95774>>>
    assertThat(readConfigFile(), Is(AppConfig("param")));
}

// -- Test with custom descriptor

// Create a (tree) description for an error.
// NB: should be locale to customDescriptor.describe(), but ceylon bugs here.
Description errorDescr(Error error) {
    Description d0 = StringDescription(normalStyle, error.msg);
    if(error.causes.empty) {
        return d0;
    } else {
        [Description*] causeDescrs = error.causes.collect((Error err) => errorDescr(err));
        return TreeDescription(d0, causeDescrs); 
    }
}

object customDescriptor satisfies Descriptor {
    value default = DefaultDescriptor();
    shared actual String describe(Object? obj, FootNoteCollector footNoteCollector) {
        
        if(is Error obj) {
            FootNote footNote = footNoteCollector.newFootNote(errorDescr(obj));
            return "Error: " + obj.msg + " (see [``footNote.reference``])";
        }
        if(is AppConfig obj) {
            return "AppConfig[ " + obj.appParam + " ])";
        }
        return default.describe(obj, footNoteCollector);
    }
}
// Resolver for custom classes
object customMatcherResolver satisfies OptionalMatcherResolver {
   shared actual Matcher? findMatcher(Object? expected/*, MatcherResolver childrenMatcherResolver*/) {
       // Add matchers for custom classes
       if(is AppConfig expected) {
           
           return ObjectMatcher<AppConfig>(expected, {
               // This FieldAdapter won't be really used here, as matching will fail on data *types*.
               FieldAdapter<AppConfig>("name", (AppConfig expected) => EqualsMatcher(expected.appParam), (AppConfig actual)=>actual.appParam)
           }, customDescriptor /*The right one*/);
       }
       return null;    // for other classes
   }
}
// Resolver for everything
MatcherResolver resolver = DefaultMatcherResolver({customMatcherResolver}, customDescriptor);

    
void testConfigFileWithFootnotes() {
//    assertThat(readConfigFile(), EqualsMatcher(AppConfig("param"), customDescriptor));
//    assertThat(readConfigFile(), ObjectMatcher<AppConfig>(AppConfig("---"), {
//        }, customDescriptor));
    //assertThat([readConfigFile(), readConfigFile(), readConfigFile()], 
    //    ListMatcher([AppConfig(""), AppConfig(""), AppConfig("")], customDescriptor), null, resolver);
//
//    assertThat([[readConfigFile()]], Is([[AppConfig("")]], resolver), null, resolver);
    //assertThat(HashMap<String, Object>{"a" -> readConfigFile()}, 
    //        Is(HashMap<String, Object>{"a" -> AppConfig("param")}, resolver));
    assertThat(readConfigFile(), Is(AppConfig(""), resolver));
}






