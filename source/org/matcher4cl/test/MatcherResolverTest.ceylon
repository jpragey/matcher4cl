import ceylon.test { assertEquals, TestRunner, PrintingTestListener }
import org.matcher4cl.core{ DefaultMatcherResolver, MatcherResolver }


void matcherResolverTest() {
    String matcherClassName(Object? obj) {
        MatcherResolver mr = DefaultMatcherResolver();
        return className(mr.findMatcher(obj));
    }
    
    assertEquals("org.matcher4cl.core::EqualsMatcher", matcherClassName(""));
    assertEquals("org.matcher4cl.core::EqualsMatcher", matcherClassName(42));
    assertEquals("org.matcher4cl.core::EqualsMatcher", matcherClassName(null));
    assertEquals("org.matcher4cl.core::ListMatcher", matcherClassName({"Hello", "World"}));
    assertEquals("org.matcher4cl.core::ListMatcher", matcherClassName({}));
    assertEquals("org.matcher4cl.core::MapMatcher", matcherClassName(LazyMap{""->""}));
    assertEquals("org.matcher4cl.core::MapMatcher", matcherClassName({""->""}));
}



void matcherResolverTestSuite() {
    TestRunner testRunner = TestRunner();
    testRunner.addTestListener(PrintingTestListener());

    testRunner.addTest("org.matcher4cl.core::matcherResolverTest", matcherResolverTest);
    
    testRunner.run();
}
