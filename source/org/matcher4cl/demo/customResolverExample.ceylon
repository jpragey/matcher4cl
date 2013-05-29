import org.matcher4cl.core{ assertThat, EqualsMatcher, ObjectMatcher, Matcher, DefaultMatcherResolver, Is, ListMatcher, OptionalMatcherResolver, Descriptor, DefaultDescriptor, FieldAdapter, DescriptorEnv }


void customResolverTest() {
    // Class under test
    class User(name, age) {
        shared String name; 
        shared Integer age;
    }
    
    // Our custom matcher
    class UserMatcher(User user) extends ObjectMatcher<User>(user, {
        FieldAdapter<User>("name", (User expected) => EqualsMatcher(expected.name), (User actual)=>actual.name),
        FieldAdapter<User>("age", (User expected) => EqualsMatcher(expected.age), (User actual)=>actual.age)
    }) {}
    
    object customMatcherResolver satisfies OptionalMatcherResolver {
        shared actual Matcher? findMatcher(Object? expected/*, MatcherResolver childrenMatcherResolver*/) {
            if(is User expected) {
                return UserMatcher(expected);
            }
            return null;
        }
    }
    value customResolver = DefaultMatcherResolver({customMatcherResolver});
    
    assertThat({User("Ted", 30), User("John", 20)}, 
        ListMatcher({User("Ted", 30), User("John", 21)}), null, customResolver);
        
    class MyIs(Object? expected) extends Is (expected, customResolver){}
    void myAssertThat(Object? actual, Matcher matcher, String? userMsg = null) =>
        assertThat(actual, matcher, userMsg ,customResolver    ); 
    myAssertThat({User("Ted", 30)}, MyIs({User("John", 20)}));
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
    class UserMatcher(User user, Descriptor descriptor) extends ObjectMatcher<User>(user, {
        FieldAdapter<User>("name", (User expected) => EqualsMatcher(expected.name), (User actual)=>actual.name),
        FieldAdapter<User>("phones", (User expected) => ListMatcher(expected.phones, descriptor), (User actual)=>actual.phones)
    }) {}
    class PhoneMatcher(Phone phone) extends ObjectMatcher<Phone>(phone, {
        FieldAdapter<Phone>("nb", (Phone expected) => EqualsMatcher(expected.phoneNb), (Phone actual)=>actual.phoneNb)
    }) {}
    
    class CustomResolver(Descriptor descriptor) satisfies OptionalMatcherResolver {
        shared actual Matcher? findMatcher(Object? expected/*, MatcherResolver childrenMatcherResolver*/) {
            
            switch(expected)
            case(is User) {return UserMatcher(expected, descriptor);}
            case(is Phone) {return PhoneMatcher(expected);}
            else {return null;}
        }
    }
    value customResolver = DefaultMatcherResolver({CustomResolver(customDescriptor)}, customDescriptor);
    
    assertThat({User("Ted", {Phone("00000")})}, 
        ListMatcher( {User("Ted", {Phone("00000"), Phone("00001")})}, customDescriptor), null, customResolver);
}



