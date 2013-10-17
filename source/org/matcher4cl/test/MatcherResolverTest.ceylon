import ceylon.test { assertEquals, TestRunner, createTestRunner, test }
import org.matcher4cl.core { defaultResolver }


test void matcherResolverTest() {
    String matcherClassName(Object? obj) {
        value mr = defaultResolver();
        return className(mr(obj));
    }
    
    assertEquals("org.matcher4cl.core.StringMatcher", matcherClassName(""));
    assertEquals("org.matcher4cl.core.EqualsMatcher", matcherClassName(42));
    assertEquals("org.matcher4cl.core.EqualsMatcher", matcherClassName(null));
    assertEquals("org.matcher4cl.core.ListMatcher", matcherClassName({"Hello", "World"}));
    assertEquals("org.matcher4cl.core.ListMatcher", matcherClassName({}));
    assertEquals("org.matcher4cl.core.MapMatcher", matcherClassName(LazyMap{""->""}));
    assertEquals("org.matcher4cl.core.MapMatcher", matcherClassName({""->""}));
}

