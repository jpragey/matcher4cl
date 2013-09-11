import org.matcher4cl.core { Descriptor, DefaultDescriptor, DescriptorEnv, Matcher, ObjectMatcher, defaultResolver, EqualsMatcher, 
    FieldAdapter, defaultAssertThat = assertThat, Is}

// Some custom class
shared class MyClass(shared String text) {}

// Customization repository
object testTools {
    
    // Descriptor for all custom classes that requires it
    value descriptor => DefaultDescriptor(
        (Object? obj, DescriptorEnv descriptorEnv)  {
           // Add descriptions for custom classes that needs one (usually not necessary)
           if(is MyClass obj) {
               return "";   // description of MyClass; create footnote(s) if needed
           }
           // Fallback to default descriptor for other objects
           return null;
        });
    
    // Our custom resolver, returns default matchers if expected if not a User
    shared Matcher(Object?) resolver = defaultResolver(
        (Object? expected) {
           if(is MyClass expected) {
               return ObjectMatcher<MyClass>(expected, {
                   // Add a FieldAdapter<MyClass> for each field here
                   FieldAdapter<MyClass>("text", EqualsMatcher(expected.text), (MyClass act) => act.text)
               }) ;
           }
           return null;
        },
    descriptor);
    
}    
 
shared void assertThat(Object? actual, Matcher matcher)
   => defaultAssertThat(actual, matcher, testTools.resolver); 
    
void test() {
    assertThat(MyClass("a") /*actual*/, Is(MyClass("a")) /*expected*/);
    assertThat(42, Is(42));
    assertThat([MyClass("a"), 42, "Hello"], Is([MyClass("a"), 43, "Hello"]) /*expected*/);
}
