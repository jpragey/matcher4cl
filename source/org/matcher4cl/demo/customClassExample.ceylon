import org.matcher4cl.core { assertThat, FieldAdapter, EqualsMatcher, ObjectMatcher }

void customClassTest() {
    // Class under test
    class User(shared String name, shared Integer age) {}
    
    // Our custom matcher
    class UserMatcher(User expected) extends ObjectMatcher<User>(expected, {
        FieldAdapter<User>("name", EqualsMatcher(expected.name), (User actual)=>actual.name),
        FieldAdapter<User>("age", EqualsMatcher(expected.age), (User actual)=>actual.age)
    }) {}
        
    // The test
    assertThat(User("Ted", 30), UserMatcher(User("John", 20)));
}
