import org.matcher4cl.core{ assertThat, EqualsMatcher, ObjectMatcher, Matcher, Is, ListMatcher, Descriptor, DefaultDescriptor, FieldAdapter, DescriptorEnv, defaultResolver, ThrowingResultHandler, IgnoreMissingAdapters }

// Class under test: User with several phones
shared class Phone(shared String phoneNb) {}
shared class User(shared String name, shared {Phone*} phones) {}

void customResolverWithDescriptorTest() {
    
    
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
        // 'name' field: ObjectMatcher provides it by reflection
        // 'phones' the (custom) descriptor is passed to the phones ListMatcher
        FieldAdapter<User>("phones", ListMatcher(expected.phones, descriptor), (User actual)=>actual.phones)
    }) {}
    class PhoneMatcher(Phone expected) extends ObjectMatcher<Phone>(expected) {}
    
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




