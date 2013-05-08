
import org.matcher4cl.core{ assertThat, TypeMatcher }

void typeMatcherExample() {
    assertThat("Hello", TypeMatcher<Integer>());
}
