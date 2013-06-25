import org.matcher4cl.core { Descriptor, DefaultDescriptor, DescriptorEnv, Matcher, ObjectMatcher, defaultMatcherResolver, EqualsMatcher, FieldAdapter }
import org.matcher4cl.core { defaultAssertThat = assertThat, Is}

// Some custom class
shared class MyClass(shared String text) {}

// Customization repository
object testTools {
    
    // Descriptor for all custom classes that requires it
    object descriptor satisfies Descriptor {
       value default = DefaultDescriptor();
       shared actual String describe(Object? obj, DescriptorEnv descriptorEnv) {
           // Add descriptions for custom classes that needs one (usually not necessary)
           if(is MyClass obj) {
               return "";   // description of MyClass; create footnote(s) if needed
           }
           // Fallback to default descriptor for other objects
           return default.describe(obj, descriptorEnv);
       }
    }
    
    // Resolver for custom classes
    Matcher? customMatcherResolver(Object? expected) {
       if(is MyClass expected) {
           return ObjectMatcher<MyClass>(expected, {
               // Add a FieldAdapter<MyClass> for each field here
               FieldAdapter<MyClass>("text", EqualsMatcher(expected.text), (MyClass act) => act.text)
           }) ;
       }
       return null;
    }
    
    // Our custom resolver, returns default matchers if expected if not a User
    shared Matcher(Object?) resolver = defaultMatcherResolver({customMatcherResolver}, descriptor);
}    
 
shared void assertThat(Object? actual, Matcher matcher, String? userMessage= null)
   => defaultAssertThat(actual, matcher, testTools.resolver, userMessage); 
    
void test() {
    assertThat(MyClass("a") /*actual*/, Is(MyClass("a")) /*expected*/);
    assertThat(42, Is(42));
    assertThat([MyClass("a"), 42, "Hello"], Is([MyClass("a"), 43, "Hello"]) /*expected*/);
}
