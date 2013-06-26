import org.matcher4cl.core{ assertThat, EqualsMatcher, ObjectMatcher, Matcher, Is, ListMatcher, Descriptor, DefaultDescriptor, FieldAdapter, DescriptorEnv, defaultResolver, ThrowingResultHandler }


void customResolverTest() {
    // Class under test
    class User(shared String name, shared Integer age) {}
    
    // Our custom matcher
    class UserMatcher(User expected) extends ObjectMatcher<User>(expected, {
        FieldAdapter<User>("name", EqualsMatcher(expected.name), (User actual)=>actual.name),
        FieldAdapter<User>("age",  EqualsMatcher(expected.age), (User actual)=>actual.age)
    }) {}
    
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
        
    void myAssertThat(Object? actual, Matcher matcher, String? userMsg = null) =>
        assertThat(actual, matcher, customResolver, userMsg); 
    myAssertThat({User("Ted", 30)}, Is({User("John", 20)}));
}


void customResolverWithDescriptorTest() {
    
    // Class under test: User with several phones
    class Phone(shared String phoneNb) {}
    class User(shared String name, shared {Phone*} phones) {}
    
    // Custom descriptor
    object customDescriptor satisfies Descriptor {
        value default = DefaultDescriptor();
        shared actual String describe(Object? obj, DescriptorEnv descriptorEnv) {
            if(is User obj) {
                return "User " + obj.name + ", phones: " + obj.phones.string;
            }
            if(is Phone obj) {
                return "Phone: " + obj.phoneNb;
            }
            return default.describe(obj, descriptorEnv);
        }
    }

    // Our custom matchers
    class UserMatcher(User expected, Descriptor descriptor) extends ObjectMatcher<User>(expected, {
        FieldAdapter<User>("name", EqualsMatcher(expected.name), (User actual)=>actual.name),
        FieldAdapter<User>("phones", ListMatcher(expected.phones, descriptor), (User actual)=>actual.phones)
    }) {}
    class PhoneMatcher(Phone expected) extends ObjectMatcher<Phone>(expected, {
        FieldAdapter<Phone>("nb", EqualsMatcher(expected.phoneNb), (Phone actual)=>actual.phoneNb)
    }) {}
    
    Matcher? customResolver(Object? expected) {
        
        switch(expected)
        case(is User) {return UserMatcher(expected, customDescriptor);}
        case(is Phone) {return PhoneMatcher(expected);}
        else {return null;}
    }
    value resolver = defaultResolver(customResolver, customDescriptor);
    
    //assertThat(      {User("Ted", {Phone("00000")})}, 
    //    ListMatcher( {User("Ted", {Phone("00000"), Phone("00001")})}, customDescriptor), resolver);
    
    // Simplified by customizing assertThat()
    void myAssertThat(Object? actual, Matcher matcher, String? userMsg = null) =>
        assertThat(actual, matcher, resolver, userMsg); 

    myAssertThat( {User("Ted", {Phone("00000")})}, 
        Is(       {User("Ted", {Phone("00000"), Phone("00001")})}));
    
}




