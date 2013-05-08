import ceylon.test { assertTrue, assertFalse, assertEquals, TestRunner, PrintingTestListener }
import org.matcher4cl.core{ EqualsMatcher, ListMatcher, MapMatcher, ObjectMatcher, FieldAdapter, Is, AllMatcher, AnyMatcher, NotMatcher, TypeMatcher, DescribedAsMatcher, StringDescription, normalStyle, AnythingMatcher, NotNullMatcher, IdentifiableMatcher, FormattedDescription, DefaultFormatter, EqualsOpMatcher, DefaultDescriptor, Descriptor, highlighted }

void equalsMatcherTest() {
    
    assertTrue(EqualsMatcher(null /*expected*/).match(null).succeeded);

    assertFalse (EqualsMatcher("42" /*expected*/).match(null).succeeded);
    assertEquals(dToS(EqualsMatcher("42" /*expected*/).match(null).matchDescription), "ERR: non-null was expected: \"42\"/<<<<null>>>>");

    assertFalse (EqualsMatcher(null /*expected*/).match("42").succeeded);
    assertEquals(dToS(EqualsMatcher(null /*expected*/).match("42").matchDescription), "ERR: <null> was expected: <null>/<<<\"42\">>>");

    assertTrue(EqualsMatcher("42"/*expected*/).match("42").succeeded);
    assertEquals(dToS(EqualsMatcher("42"/*expected*/).match("42").matchDescription), "\"42\"");

}


void listMatcherTest() {
    assertTrue(ListMatcher([10, 11, 12]).match([10, 11, 12]).succeeded);
    assertEquals("{10, 11, 12}", dToS(ListMatcher([10, 11, 12]).match([10, 11, 12]).matchDescription));
    
    assertTrue(ListMatcher([]).match([]).succeeded);
    assertEquals("{}", dToS(ListMatcher([]).match([]).matchDescription));
    
    assertFalse(ListMatcher([10, 11, 12]).match([10, 101, 12]).succeeded);
    assertEquals("1 mismatched: {10, <<<At position 1 >>>\"==\": '=='11/<<<101>>>, 12}", 
        dToS(ListMatcher([10, 11, 12]).match([10, 101, 12]).matchDescription));
    
    
    assertFalse(ListMatcher([10, 11, 12]).match(null).succeeded);
    assertEquals("<<<An iterator was expected, found null>>>", dToS(ListMatcher([10, 11, 12]).match(null).matchDescription));

    assertFalse(ListMatcher([10, 11, 12]).match(42).succeeded);
    assertEquals("<<<An iterator was expected, found ceylon.language::Integer>>>", dToS(ListMatcher([10, 11, 12]).match(42).matchDescription));
    
    assertFalse(ListMatcher([10, 11, 12]).match([10, 11]).succeeded);
    assertEquals("Expected list is longer than actual: 3 expected, 2 actual:  {10, 11} => ERR 1 expected not in actual list:  {12}", 
        dToS(ListMatcher([10, 11, 12]).match([10, 11]).matchDescription));
    
    assertFalse(ListMatcher([10, 11, 12]).match([10, 11, 12, 13]).succeeded);
    assertEquals("Actual list is longer than expected: 3 expected, 4 actual:  {10, 11, 12} => ERR 1 actual not in expected list:  {13}", 
        dToS(ListMatcher([10, 11, 12]).match([10, 11, 12, 13]).matchDescription));
    
    assertFalse(ListMatcher([10, 11, [12, 13]]).match([10, 11, [12, 14]]).succeeded);
    assertEquals("1 mismatched: {10, 11, <<<At position 2 >>>\"ListMatcher\": 1 mismatched: {12, <<<At position 1 >>>\"==\": '=='13/<<<14>>>}}", 
        dToS(ListMatcher([10, 11, [12, 13]]).match([10, 11, [12, 14]]).matchDescription));
}

void mapMatcherTest() {
    assertFalse(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(null).succeeded);
    assertEquals("<<<A Map was expected, found null>>>", dToS(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(null).matchDescription));
    
    assertFalse(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(42).succeeded);
    assertEquals("<<<A Map was expected, found ceylon.language::Integer>>>", dToS(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(42).matchDescription));
    
    // Matched
    assertTrue(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(LazyMap{10->100, 11->101, 12->102}).succeeded);
    assertEquals("{10->100, 11->101, 12->102}", 
        dToS(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(LazyMap{10->100, 11->101, 12->102}).matchDescription));

    // 
    assertFalse(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(LazyMap{11->1010, 12->102, 13->103}).succeeded);
    assertEquals("1 values mismatched: {11->Value mismatch for \"==\"<<<: >>>101/<<<1010>>>, 12->102} => ERR 1 expected not in actual list:  {13->/103} => ERR 1 actual not in expected list:  {10->100/}",
        dToS(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(LazyMap{11->1010, 12->102, 13->103}).matchDescription));

    assertFalse(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(LazyMap{10->100, 11->1010, 12->102}).succeeded);
    assertEquals("1 values mismatched: {10->100, 11->Value mismatch for \"==\"<<<: >>>101/<<<1010>>>, 12->102}", 
        dToS(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(LazyMap{10->100, 11->1010, 12->102}).matchDescription));
}




void objectMatcherTest() {
    class A(name, age) {shared String name; shared Integer age;}
    {FieldAdapter<A> *} aFieldMatchers = {
        FieldAdapter<A>("name", (A expected) => EqualsMatcher(expected.name), (A actual)=>actual.name),
        FieldAdapter<A>("age", (A expected) => EqualsMatcher(expected.age), (A actual)=>actual.age)
    };
        
    ObjectMatcher<A> objectMatcher = ObjectMatcher<A> (A("John", 20), aFieldMatchers);

    assertTrue(objectMatcher.match(A("John", 20)).succeeded);
    
    assertFalse(objectMatcher.match(A("Ted", 30)).succeeded);
    assertEquals("<<<A>>> {name: ('=='\"John\"/<<<\"Ted\">>>), age: ('=='20/<<<30>>>)}", 
        dToS(objectMatcher.match(A("Ted", 30)).matchDescription));
}

void isMatcherTest() {
    assertEquals("org.matcher4cl.core::EqualsMatcher", className(Is(42).matcher));
    assertEquals("org.matcher4cl.core::EqualsMatcher", className(Is("Hello").matcher));
    assertEquals("org.matcher4cl.core::ListMatcher", className(Is({"Hello", "World"}).matcher));
    assertEquals("org.matcher4cl.core::ListMatcher", className(Is({}).matcher));
    assertEquals("org.matcher4cl.core::MapMatcher", className(Is({"H" -> "Hello", "W" -> "World"}).matcher));
}


void allMatcherTest() {

    assertTrue(AllMatcher([]).match(null).succeeded);  // No matcher => success
    assertEquals("All {}", 
        dToS(AllMatcher([]).match(null).matchDescription));
    
    assertFalse(AllMatcher([EqualsMatcher(42), EqualsMatcher(42)]).match(null).succeeded);  // No matcher => success
    assertEquals("AllMatcher: 2 mismatch (2 matchers) {\"==\": ERR: non-null was expected: 42/<<<<null>>>>, \"==\": ERR: non-null was expected: 42/<<<<null>>>>}", 
        dToS(AllMatcher([EqualsMatcher(42), EqualsMatcher(42)]).match(null).matchDescription));

    assertTrue(AllMatcher([EqualsMatcher(42), EqualsMatcher(42)]).match(42).succeeded);  // No matcher => success
    assertEquals("All {\"==\": 42, \"==\": 42}", 
        dToS(AllMatcher([EqualsMatcher(42), EqualsMatcher(42)]).match(42).matchDescription));

    assertFalse(AllMatcher([EqualsMatcher(42), EqualsMatcher(43)]).match(42).succeeded);  // No matcher => success
    assertEquals("AllMatcher: 1 mismatch (2 matchers) {\"==\": 42, \"==\": '=='43/<<<42>>>}", 
        dToS(AllMatcher([EqualsMatcher(42), EqualsMatcher(43)]).match(42).matchDescription));
}


void anyMatcherTest() {

    assertFalse(AnyMatcher([]).match(null).succeeded);  // No matcher => fail
    assertEquals("AnyMatcher: no matcher succeeded (0 matchers) {}", 
        dToS(AnyMatcher([]).match(null).matchDescription));
    
    assertFalse(AnyMatcher([EqualsMatcher(42), EqualsMatcher(42)]).match(null).succeeded);  // No matcher => success
    assertEquals("AnyMatcher: no matcher succeeded (2 matchers) {\"==\": ERR: non-null was expected: 42/<<<<null>>>>, \"==\": ERR: non-null was expected: 42/<<<<null>>>>}", 
        dToS(AnyMatcher([EqualsMatcher(42), EqualsMatcher(42)]).match(null).matchDescription));

    assertTrue(AnyMatcher([EqualsMatcher(42), EqualsMatcher(42)]).match(42).succeeded);  // No matcher => success
    assertEquals("Any {\"==\": 42, \"==\": 42}", 
        dToS(AnyMatcher([EqualsMatcher(42), EqualsMatcher(42)]).match(42).matchDescription));

    assertTrue(AnyMatcher([EqualsMatcher(42), EqualsMatcher(43)]).match(42).succeeded);  // No matcher => success
    assertEquals("Any {\"==\": 42, \"==\": '=='43/<<<42>>>}", 
        dToS(AnyMatcher([EqualsMatcher(42), EqualsMatcher(43)]).match(42).matchDescription));
}

void notMatcherTest() {
    
    assertTrue(NotMatcher(EqualsMatcher(42)).match(null).succeeded);  // No matcher => success
    assertEquals("Not {\"==\": ERR: non-null was expected: 42/<<<<null>>>>}", 
        dToS(NotMatcher(EqualsMatcher(42)).match(null).matchDescription));

    assertFalse(NotMatcher(EqualsMatcher(42)).match(42).succeeded);  // No matcher => success
    assertEquals("NotMatcher: child matcher succeeded {\"==\": 42}", 
        dToS(NotMatcher(EqualsMatcher(42)).match(42).matchDescription));
}

void anythingMatcherTest() {
    
    assertTrue(AnythingMatcher().match(null).succeeded);  // No matcher => success
    assertEquals("Anything", 
        dToS(AnythingMatcher().match(null).matchDescription));
}

void describedAsMatcherTest() {
    
    assertFalse(DescribedAsMatcher(StringDescription(normalStyle, "Response: "), EqualsMatcher(42)).match(null).succeeded);
    assertEquals("Response: ERR: non-null was expected: 42/<<<<null>>>>", 
        dToS(DescribedAsMatcher(StringDescription(normalStyle, "Response: "), EqualsMatcher(42)).match(null).matchDescription));
    
    assertTrue(DescribedAsMatcher(StringDescription(normalStyle, "Response: "), EqualsMatcher(42)).match(42).succeeded);
    assertEquals("Response: 42", 
        dToS(DescribedAsMatcher(StringDescription(normalStyle, "Response: "), EqualsMatcher(42)).match(42).matchDescription));
}

class A<T>() {
    shared actual String string = "A";
}

void typeMatcherTest() {
    
    assertTrue(TypeMatcher<String>().match("Hello").succeeded);
    assertEquals("\"Hello\"", 
        dToS(TypeMatcher<String>().match("Hello").matchDescription));
    
    assertFalse(TypeMatcher<Integer>().match("Hello").succeeded);
    assertEquals("ERR: wrong type: found ceylon.language::String: <<<\"Hello\">>>", 
        dToS(TypeMatcher<Integer>().match("Hello").matchDescription));
    
    assertFalse(TypeMatcher<Integer>().match(null).succeeded);
    assertEquals("ERR: wrong type: found <null>: <<<<null>>>>", 
        dToS(TypeMatcher<Integer>().match(null).matchDescription));
    
    
    assertTrue(TypeMatcher<Sequence<Integer>>().match({1,2,3}).succeeded);
    assertEquals("[1, 2, 3]", 
        dToS(TypeMatcher<Sequence<Integer>>().match({1,2,3}).matchDescription));
    
    assertFalse(TypeMatcher<Sequence<Integer>>().match("Hello").succeeded);
    assertEquals("ERR: wrong type: found ceylon.language::String: <<<\"Hello\">>>", 
        dToS(TypeMatcher<Sequence<Integer>>().match("Hello").matchDescription));

        
    assertFalse(TypeMatcher<A<Integer>>().match(A<String>()).succeeded);
    assertEquals("ERR: wrong type: found org.matcher4cl.test::A: <<<A>>>", 
        dToS(TypeMatcher<A<Integer>>().match(A<String>()).matchDescription));
    
    assertTrue(TypeMatcher<A<Integer>>().match(A<Integer>()).succeeded);
    assertEquals("A", 
        dToS(TypeMatcher<A<Integer>>().match(A<Integer>()).matchDescription));
    
    // Inheritance
    assertTrue(TypeMatcher<Object>().match(A<Integer>()).succeeded);
    assertEquals("A", 
        dToS(TypeMatcher<Object>().match(A<Integer>()).matchDescription));
}

void notNullMatcherTest() {
    
    assertTrue(NotNullMatcher().match("Hello").succeeded);
    assertEquals("\"Hello\"", 
        dToS(NotNullMatcher().match("Hello").matchDescription));
    
    assertFalse(NotNullMatcher().match(null).succeeded);
    assertEquals("ERR: wrong type: found <null>: <<<<null>>>>",
        dToS(NotNullMatcher().match(null).matchDescription));
}

void sameInstanceMatcherTest() {
    A<Integer> a0 = A<Integer>();
    A<Integer> a1 = A<Integer>();
     
    assertTrue(IdentifiableMatcher(a0).match(a0).succeeded);
    assertEquals("A", 
        dToS(IdentifiableMatcher(a0).match(a0).matchDescription));

    assertFalse(IdentifiableMatcher(a0).match(a1).succeeded);
    assertEquals("<<<'==='>>>A/<<<A>>>", 
        dToS(IdentifiableMatcher(a0).match(a1).matchDescription));
    
    assertFalse(IdentifiableMatcher(a0).match(12).succeeded);
    assertEquals("ERR: org.matcher4cl.test::A was expected, found ceylon.language::Integer: A/<<<12>>>", 
        dToS(IdentifiableMatcher(a0).match(12).matchDescription));
    
    assertFalse(IdentifiableMatcher(a0).match(null).succeeded);
    assertEquals("ERR: non-null was expected: A/<<<<null>>>>", 
        dToS(IdentifiableMatcher(a0).match(null).matchDescription));
}

void simpleValuesMatcherTest() {
    class FloatMatcher(
        Float expected,
        Float relativeError, 
        Descriptor descriptor = DefaultDescriptor()
    
    ) extends EqualsOpMatcher<Float>(
        expected,
        function (Float expected, Float actual) {
            // Compare with error margin
            if( (expected * (1-relativeError) <= actual <= expected * (1+relativeError)) || 
                (actual * (1-relativeError) <= expected <= actual * (1+relativeError))) {
                return null;
            } else {
                // Error message
                return FormattedDescription(DefaultFormatter("== within {}% : "), 
                    [relativeError*100], highlighted);
            }
        },
        "== within ``expected`` ", 
        descriptor){}
        
    assertFalse(FloatMatcher(1.0, 0.0001).match(0.999).succeeded);
    assertEquals("<<<== within 0.01% : >>>1.0/<<<0.999>>>", 
        dToS(FloatMatcher(1.0, 0.0001).match(0.999).matchDescription));

    assertTrue(FloatMatcher(1.0, 0.0001).match(0.9999).succeeded);
    assertEquals("1.0/0.9999", 
        dToS(FloatMatcher(1.0, 0.0001).match(0.9999).matchDescription));
    
}

void matcherTestSuite0() {
    equalsMatcherTest();
    listMatcherTest(); 
    mapMatcherTest();
    objectMatcherTest();
    isMatcherTest();
    allMatcherTest();
    anyMatcherTest();
    notMatcherTest();
    anythingMatcherTest();
    describedAsMatcherTest();
    typeMatcherTest();
    sameInstanceMatcherTest();
    simpleValuesMatcherTest();
}

void matcherTestSuite() {
    TestRunner testRunner = TestRunner();
    testRunner.addTestListener(PrintingTestListener());

    testRunner.addTest("org.jpr.matchers.core::equalsMatcherTest", equalsMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::listMatcherTest", listMatcherTest); 
    testRunner.addTest("org.jpr.matchers.core::mapMatcherTest", mapMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::objectMatcherTest", objectMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::isMatcherTest", isMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::allMatcherTest", allMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::anyMatcherTest", anyMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::notMatcherTest", notMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::anythingMatcherTest", anythingMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::describedAsMatcherTest", describedAsMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::typeMatcherTest", typeMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::sameInstanceMatcherTest", sameInstanceMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::notNullMatcherTest", notNullMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::simpleValuesMatcherTest", simpleValuesMatcherTest);
    
    testRunner.run();
    
}

