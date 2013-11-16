import org.matcher4cl.core{ assertThat, EqualsMatcher, ObjectMatcher, Matcher, Is, ListMatcher, Descriptor, DefaultDescriptor, FieldAdapter, DescriptorEnv, defaultResolver, ThrowingResultHandler, IgnoreMissingAdapters }

// Class under test: User with several phones
//shared class Phone(shared String phoneNb) {}
//shared class User(shared String name, shared {Phone*} phones) {}
shared class User(shared String name) {}
shared class Account(shared String userId) {}

void test() {
    
    // Custom descriptor
    value descriptor = DefaultDescriptor(
        (Object? obj, DescriptorEnv descriptorEnv) {
        
        switch(obj)
        case (is Account) {return "Account [``obj.userId``]";}
        else {return null;}
    });

    // Our custom matchers
//    class UserMatcher(User expected/*, Descriptor descriptor*/) extends ObjectMatcher<User>(expected, {}, descriptor) {}
    
    value resolver = defaultResolver(
        (Object? expected) {
            switch(expected)
//            case(is User) {return UserMatcher(expected/*, descriptor*/);}
            case(is User) {return ObjectMatcher<User>(expected, {}, descriptor);}   // Note: descriptor arg
            else {return null;}
        }, 
        descriptor
    );
    
    //assertThat(      {User("Ted", {Phone("00000")})}, 
    //    ListMatcher( {User("Ted", {Phone("00000"), Phone("00001")})}, customDescriptor), resolver);
    
    // Simplified by customizing assertThat()
    void myAssertThat(Object? actual, Matcher matcher) =>
        assertThat(actual, matcher, resolver); 

    //myAssertThat( {User("Ted", {Phone("00000")})}, 
    //    Is(       {User("Ted", {Phone("00000"), Phone("00001")})}));
    //myAssertThat( {User("Ted", Phone("00000"))}, 
    //    Is(       {User("Ted", Phone("00001"))}));
    
    // Use UserMatcher descriptor
////    myAssertThat( Account("123456"), Is(User("Ted")));


    myAssertThat( {Account("123456")}, Is({User("Ted")}));
    
}




