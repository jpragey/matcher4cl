import org.matcher4cl.core{ assertThat, Is, Descriptor, DefaultDescriptor, Matcher, ObjectMatcher, FieldAdapter, EqualsMatcher, ListMatcher, ThrowingResultHandler, Description, StringDescription, TextStyle, normalStyle, CompoundDescription, FootNote, TreeDescription, DescriptorEnv, defaultMatcherResolver }
import ceylon.collection { HashMap }


void customDescriptorTest() {
    // Class under test
    class Complex(shared Float re, shared Float im) {
        // Simple matching: defaultMatcherResolver returns an EqualMatcher 
        // (which calls equals()) for unknown objects: 
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
        shared actual String describe(Object? obj, DescriptorEnv descriptorEnv) {
            if(is Complex obj) {
                return "" + obj.re.string + " + " + obj.im.string + "i ";
            }
            return default.describe(obj, descriptorEnv);
        }
    }
    
    //assertThat(Complex(1.0, 0.1), Is(Complex(1.0, 0.0)), 
    //    (Object? expected) => defaultMatcherResolver({}, descriptor)(expected)
    //    );
    
    value resolver = (Object? expected) => defaultMatcherResolver({}, descriptor)(expected);
    void myAssertThat(Object? actual, Matcher matcher, String? userMsg = null) =>
        assertThat(actual, matcher, resolver, userMsg); 

    myAssertThat(Complex(1.0, 0.1), Is(Complex(1.0, 0.0)));
    
    
}

// **********************************************************************************
// *                                    FootNotes                                   * 
// **********************************************************************************

class Error(shared String msg, shared {Error*} causes = {}) {}
class AppConfig(shared String appParam/*application configuration here*/) {}
AppConfig|Error parseConfigFile(/*file path omitted for brevity*/) {
    // Fails, in this example
    return 
    Error("Can't open application", {
        Error("Error reading config file 'myapp.config'", {
            Error("Config parameter xyz not found."),
            Error("Config parameter tuv: invalid syntax.")
        })}); 
}

// -- Basic test
void poorTestConfigFile() {    // Message is '=='org.matcher4cl.demo.AppConfig@7e1c8e60/<<<org.matcher4cl.demo.Error@1ab95774>>>
    assertThat(parseConfigFile(), Is(AppConfig("param")));
}

// -- Test with custom descriptor

// Convert an error tree to a TreeDescription.
// NB: should be locale to customDescriptor.describe(), but ceylon bugs here.
Description describeErrorTree(Error error) {
    Description d = StringDescription(error.msg);
    if(error.causes.empty) {
        return d;
    } else {
        [Description*] causeDescrs = error.causes.collect((Error err) => describeErrorTree(err));
        return TreeDescription(d, causeDescrs); 
    }
}

object customDescriptor satisfies Descriptor {
    value default = DefaultDescriptor();
    shared actual String describe(Object? obj, DescriptorEnv descriptorEnv) {
        
        if(is Error obj) {
            FootNote footNote = descriptorEnv.newFootNote(describeErrorTree(obj));
            return "Error: ``obj.msg`` (see [``footNote.reference``])";
        }
        if(is AppConfig obj) {
            return "AppConfig[ " + obj.appParam + " ])";
        }
        return default.describe(obj, descriptorEnv);
    }
}

Matcher? customMatcherResolver(Object? expected) {
    // Add matchers for custom classes
    if(is AppConfig expected) {
        
        return ObjectMatcher<AppConfig>(expected, {
            // This FieldAdapter won't be really used here, as matching will fail on data *types*.
            FieldAdapter<AppConfig>("name", (AppConfig expected) => EqualsMatcher(expected.appParam), (AppConfig actual)=>actual.appParam)
        }, customDescriptor /*The right one*/);
    }
    return null;    // for other classes
}
   
// Resolver for everything
    Matcher (Object? ) resolver = defaultMatcherResolver({customMatcherResolver}, customDescriptor);

    
void testConfigFileWithFootnotes() {
    assertThat(parseConfigFile(), EqualsMatcher(AppConfig("param"), customDescriptor));
//    assertThat(parseConfigFile(), ObjectMatcher<AppConfig>(AppConfig("---"), {
//        }, customDescriptor));
    //assertThat([parseConfigFile(), readConfigFile(), readConfigFile()], 
    //    ListMatcher([parseConfigFile(""), AppConfig(""), AppConfig("")], customDescriptor), null, resolver);
//
//    assertThat([[parseConfigFile()]], Is([[AppConfig("")]], resolver), null, resolver);
    //assertThat(HashMap<String, Object>{"a" -> readConfigFile()}, 
    //        Is(HashMap<String, Object>{"a" -> AppConfig("param")}, resolver));
//    assertThat(parseConfigFile(), Is(AppConfig(""), resolver));
}






