import org.matcher4cl.core { assertThat, FieldAdapter, EqualsMatcher, ObjectMatcher, DefaultDescriptor, IgnoreMissingAdapters }

//shared class User(shared String name, shared Integer age) {}

void customClassTest() {
    // Class under test
    class User(shared String name, shared Integer age) {}
    // Our custom matcher
    class UserMatcher(User expected) extends ObjectMatcher<User>(expected, {
        FieldAdapter<User>(`User.name`, EqualsMatcher(expected.name)/*, (User actual)=>actual.name*/),
        FieldAdapter<User>(`User.age`, EqualsMatcher(expected.age)/*, (User actual)=>actual.age*/)
    }, 
    DefaultDescriptor(),    // Descriptor: see later 
    IgnoreMissingAdapters<User>()
    ) {}
    // The test
    assertThat(User("Ted", 30), UserMatcher(User("John", 20)));
}
