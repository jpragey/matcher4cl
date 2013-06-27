import org.matcher4cl.core{ assertThat, EqualsMatcher, ObjectMatcher, Matcher, Is, ListMatcher, Descriptor, DefaultDescriptor, FieldAdapter, DescriptorEnv, defaultResolver, ThrowingResultHandler, IgnoreMissingAdapters }

// Class under test
shared class User(shared String name, shared Integer age) {}
    
void customResolverTest() {
    // Class under test
//    class User(shared String name, shared Integer age) {}
    
    // Our custom matcher
    class UserMatcher(User expected) extends ObjectMatcher<User>(expected) {}
    
    // Our custom resolver, returns null if expected if not a User
    Matcher? customMatcherResolver(Object? expected) {
        if(is User expected) {
            return UserMatcher(expected);
        }
        return null;
    }
  
    // Our custom resolver, returns default matchers if expected if not a User
    value customResolver = defaultResolver(customMatcherResolver);
    
    // Fire!
    //assertThat(     {User("Ted", 30), User("John", 20)}, 
    //    ListMatcher({User("Ted", 30), User("John", 21)}), customResolver);
        
    void myAssertThat(Object? actual, Matcher matcher) =>
        assertThat(actual, matcher, customResolver); 
    
    myAssertThat({User("Ted", 30)}, Is({User("John", 20)}));
}
