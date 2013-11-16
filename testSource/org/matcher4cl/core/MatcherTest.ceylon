import ceylon.test { assertTrue, assertFalse, assertEquals, TestRunner, fail, createTestRunner, TestListener, TestResult, failure, error, TestDescription, test }

import org.matcher4cl.core { dToS }

test void equalsMatcherTest() {
    
    assertTrue(EqualsMatcher(null /*expected*/).match(null).succeeded);

    assertFalse (EqualsMatcher("42" /*expected*/).match(null).succeeded);
    assertEquals(dToS(EqualsMatcher("42" /*expected*/).match(null).matchDescription), "ERR: non-null was expected: \"42\"/<<<<null>>>>");

    assertFalse (EqualsMatcher(null /*expected*/).match("42").succeeded);
    assertEquals(dToS(EqualsMatcher(null /*expected*/).match("42").matchDescription), "ERR: <null> was expected: <null>/<<<\"42\">>>");

    assertTrue(EqualsMatcher("42"/*expected*/).match("42").succeeded);
    assertEquals(dToS(EqualsMatcher("42"/*expected*/).match("42").matchDescription), "\"42\"");

}


test void listMatcherTest() {
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
    assertEquals("<<<An iterator was expected, found ceylon.language.Integer>>> value = 42", dToS(ListMatcher([10, 11, 12]).match(42).matchDescription)); // TODO: better expr
    //<<<An iterator was expected, found ceylon.language::Integer>>> != <<<An iterator was expected, found ceylon.language::Integer>>>42"
                                                                                                                                       
    assertFalse(ListMatcher([10, 11, 12]).match([10, 11]).succeeded);
    assertEquals("Expected list is longer than actual: 3 expected, 2 actual:  {10, 11} => ERR 1 expected not in actual list:  {12}", 
        dToS(ListMatcher([10, 11, 12]).match([10, 11]).matchDescription));
    
    assertFalse(ListMatcher([10, 11, 12]).match([10, 11, 12, 13]).succeeded);
    assertEquals("Actual list is longer than expected: 3 expected, 4 actual:  {10, 11, 12} => ERR 1 actual not in expected list:  {13}", 
        dToS(ListMatcher([10, 11, 12]).match([10, 11, 12, 13]).matchDescription));
    
    assertFalse(ListMatcher([10, 11, [12, 13]]).match([10, 11, [12, 14]]).succeeded);
    assertEquals("1 mismatched: {10, 11, <<<At position 2 >>>\"ListMatcher\": 1 mismatched: {12, <<<At position 1 >>>\"==\": '=='13/<<<14>>>}}", 
        dToS(ListMatcher([10, 11, [12, 13]]).match([10, 11, [12, 14]]).matchDescription));

    // -- Tuples containing nulls
        
    assertTrue(ListMatcher([10, 11, null]).match([10, 11, null]).succeeded);
    assertTrue(ListMatcher([null]).match([null]).succeeded);
    
    assertFalse(ListMatcher([10]).match([null]).succeeded);
    assertEquals("1 mismatched: {<<<At position 0 >>>\"==\": ERR: non-null was expected: 10/<<<<null>>>>}", dToS(ListMatcher([10]).match([null]).matchDescription));
    
    assertFalse(ListMatcher([null]).match([10]).succeeded);
    assertEquals("1 mismatched: {<<<At position 0 >>>\"==\": ERR: <null> was expected: <null>/<<<10>>>}", dToS(ListMatcher([null]).match([10]).matchDescription));
    
    assertFalse(ListMatcher([10, null]).match([10]).succeeded);
    assertEquals("Expected list is longer than actual: 2 expected, 1 actual:  {10} => ERR 1 expected not in actual list:  {<null>}", dToS(ListMatcher([10, null]).match([10]).matchDescription));
    
    assertFalse(ListMatcher([10]).match([10, null]).succeeded);
    assertEquals("Actual list is longer than expected: 1 expected, 2 actual:  {10} => ERR 1 actual not in expected list:  {<null>}", dToS(ListMatcher([10]).match([10, null]).matchDescription));
}

test void mapMatcherTest() {
    assertFalse(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(null).succeeded);
    assertEquals("<<<A Map was expected, found null>>>", dToS(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(null).matchDescription));
    
    assertFalse(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(42).succeeded);
    assertEquals("<<<A Map was expected, found ceylon.language.Integer>>>", dToS(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(42).matchDescription));
    
    // Matched
    assertTrue(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(LazyMap{10->100, 11->101, 12->102}).succeeded);
    assertEquals("{10->100, 11->101, 12->102}", 
        dToS(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(LazyMap{10->100, 11->101, 12->102}).matchDescription));

    // 
    assertFalse(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(LazyMap{11->1010, 12->102, 13->103}).succeeded);

    assertEquals("1 values mismatched: {11->Value mismatch for \"==\": 101/<<<1010>>>Cause:'=='101/<<<1010>>>, 12->102} => ERR 1 expected not in actual list:  {13->/103} => ERR 1 actual not in expected list:  {10->100/}",
        dToS(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(LazyMap{11->1010, 12->102, 13->103}).matchDescription));

    assertFalse(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(LazyMap{10->100, 11->1010, 12->102}).succeeded);
    assertEquals("1 values mismatched: {10->100, 11->Value mismatch for \"==\": 101/<<<1010>>>Cause:'=='101/<<<1010>>>, 12->102}", 
        dToS(MapMatcher(LazyMap{10->100, 11->101, 12->102}).match(LazyMap{10->100, 11->1010, 12->102}).matchDescription));


    assertFalse(MapMatcher(LazyMap{"a"->"b"}).match(LazyMap{"a"->"c"}).succeeded);
    ////assertEquals("", dToS(MapMatcher(LazyMap{"a"->"b"}).match(LazyMap{"a"->"c"}).matchDescription));
}


shared class AAA(shared String name, shared Integer age) {}
shared class TestClass0(name, age) {shared String name; shared Integer age;}


Boolean printDescrIfFails(MatcherResult matcherResult) {
    
    if(matcherResult.succeeded) {
        return true;
    } else {
        print( matcherResult.matchDescription.toString(SimpleDescrWriter{
            multiLine = true;
        }));
        return false;
    }
    
}

test void objectMatcherTest() {
    TestClass0 expected = TestClass0("John", 20);
    {FieldAdapter<TestClass0> *} aFieldMatchers = {
        FieldAdapter<TestClass0>(`TestClass0.name`, EqualsMatcher(expected.name)),
        FieldAdapter<TestClass0>(`TestClass0.age`, EqualsMatcher(expected.age))
    };
        
    ObjectMatcher<TestClass0> objectMatcher = ObjectMatcher<TestClass0> (expected, aFieldMatchers);

    assertTrue(printDescrIfFails(objectMatcher.match(TestClass0("John", 20))));
    
    assertFalse(objectMatcher.match(TestClass0("Ted", 30)).succeeded);
    assertEquals("<<<org.matcher4cl.core.TestClass0>>> {name: ('=='\"John\"/<<<\"Ted\">>>), age: ('=='20/<<<30>>>)}", 
        dToS(objectMatcher.match(TestClass0("Ted", 30)).matchDescription));
    
}

shared class SharedTopLevel(shared String str0, shared String str, shared Integer int) {}

class NonSharedTopLevel    (shared String str0, shared String str, shared Integer int) {}


shared class ObjectMatcherTester() {
    shared class SharedNested(shared String str0, shared String str, shared Integer int) {}
    class     NonSharedNested(shared String str0, shared String str, shared Integer int) {}
    
    void doTest<T>(Object actual, ObjectMatcher<T> matcher, Boolean matchResult, String msg) given T satisfies Object {
        assertEquals(matchResult, matcher.match(actual).succeeded);
        assertEquals(msg, dToS(matcher.match(actual).matchDescription));
    }
    //Attribute<Nothing, Anything> att = `SharedTopLevel.str0`;
    shared void allSharedTopLevelTests() {
        ObjectMatcher<SharedTopLevel> matcher(SharedTopLevel expected, MissingAdapterStrategy<SharedTopLevel> strategy)  
            => ObjectMatcher<SharedTopLevel> (expected, {
            FieldAdapter<SharedTopLevel>(`SharedTopLevel.str0`,   EqualsMatcher(expected.str0))
                }, DefaultDescriptor(), strategy);
                
        // SharedTopLevel
        doTest(SharedTopLevel("a", "b", 42), matcher(SharedTopLevel("a", "b", 42), FailForMissingAdapter<SharedTopLevel>()), 
                false, "Class field(s) without FieldAdapter: str, int");
        doTest(SharedTopLevel("a", "b", 42), matcher(SharedTopLevel("a", "b", 42), IgnoreMissingAdapters<SharedTopLevel>()), 
                true, "org.matcher4cl.core.SharedTopLevel {str0: (\"a\")}");
        doTest(SharedTopLevel("a", "b", 42), matcher(SharedTopLevel("a", "b", 42), CreateMissingAdapters<SharedTopLevel>()), 
                true, "org.matcher4cl.core.SharedTopLevel {str0: (\"a\"), str: (\"b\"), int: (42)}");
        
        doTest(SharedTopLevel("a", "x", 42), matcher(SharedTopLevel("a", "b", 42), FailForMissingAdapter<SharedTopLevel>()), 
                false, "Class field(s) without FieldAdapter: str, int");
        doTest(SharedTopLevel("a", "x", 42), matcher(SharedTopLevel("a", "b", 42), IgnoreMissingAdapters<SharedTopLevel>()), 
                true, "org.matcher4cl.core.SharedTopLevel {str0: (\"a\")}");
        doTest(SharedTopLevel("a", "x", 42), matcher(SharedTopLevel("a", "b", 42), CreateMissingAdapters<SharedTopLevel>()), 
                false, "<<<org.matcher4cl.core.SharedTopLevel>>> {str0: (\"a\"), str: (\"b\"/<<<\"x\">>>: expected[0]='b'(98=#62) != actual[0]='x'(120=#78)), int: (42)}");

    }
    
    shared void allNonSharedTopLevelTests() {
        ObjectMatcher<NonSharedTopLevel> matcher(NonSharedTopLevel expected, MissingAdapterStrategy<NonSharedTopLevel> strategy)  
            => ObjectMatcher<NonSharedTopLevel> (expected, {
            FieldAdapter<NonSharedTopLevel>(`NonSharedTopLevel.str0`,   EqualsMatcher(expected.str0))
                }, DefaultDescriptor(), strategy);
                
        // NonSharedTopLevel
        doTest(NonSharedTopLevel("a", "b", 42), matcher(NonSharedTopLevel("a", "b", 42), FailForMissingAdapter<NonSharedTopLevel>()), 
                false, "Class field(s) without FieldAdapter: str, int");
        doTest(NonSharedTopLevel("a", "b", 42), matcher(NonSharedTopLevel("a", "b", 42), IgnoreMissingAdapters<NonSharedTopLevel>()), 
                true, "org.matcher4cl.core.NonSharedTopLevel {str0: (\"a\")}");
        doTest(NonSharedTopLevel("a", "b", 42), matcher(NonSharedTopLevel("a", "b", 42), CreateMissingAdapters<NonSharedTopLevel>()), 
                true, "org.matcher4cl.core.NonSharedTopLevel {str0: (\"a\"), str: (\"b\"), int: (42)}");
        
        doTest(NonSharedTopLevel("a", "x", 42), matcher(NonSharedTopLevel("a", "b", 42), FailForMissingAdapter<NonSharedTopLevel>()), 
                false, "Class field(s) without FieldAdapter: str, int");
        doTest(NonSharedTopLevel("a", "x", 42), matcher(NonSharedTopLevel("a", "b", 42), IgnoreMissingAdapters<NonSharedTopLevel>()), 
                true, "org.matcher4cl.core.NonSharedTopLevel {str0: (\"a\")}");
        doTest(NonSharedTopLevel("a", "x", 42), matcher(NonSharedTopLevel("a", "b", 42), CreateMissingAdapters<NonSharedTopLevel>()), 
                false, "<<<org.matcher4cl.core.NonSharedTopLevel>>> {str0: (\"a\"), str: (\"b\"/<<<\"x\">>>: expected[0]='b'(98=#62) != actual[0]='x'(120=#78)), int: (42)}");
    }
    
    shared void allSharedNestedLevelTests() {
        ObjectMatcher<SharedNested> matcher(SharedNested expected, MissingAdapterStrategy<SharedNested> strategy)  
            => ObjectMatcher<SharedNested> (expected, {
            FieldAdapter<SharedNested>(`SharedNested.str0`,   EqualsMatcher(expected.str0))
                }, DefaultDescriptor(), strategy);
                
        doTest(SharedNested("a", "b", 42), matcher(SharedNested("a", "b", 42), FailForMissingAdapter<SharedNested>()), 
                false, "Class field(s) without FieldAdapter: str, int");
        doTest(SharedNested("a", "b", 42), matcher(SharedNested("a", "b", 42), IgnoreMissingAdapters<SharedNested>()), 
                true, "org.matcher4cl.core.ObjectMatcherTester$SharedNested {str0: (\"a\")}");
        doTest(SharedNested("a", "b", 42), matcher(SharedNested("a", "b", 42), CreateMissingAdapters<SharedNested>()), 
                true, "org.matcher4cl.core.ObjectMatcherTester$SharedNested {str0: (\"a\"), str: (\"b\"), int: (42)}");
        
        doTest(SharedNested("a", "x", 42), matcher(SharedNested("a", "b", 42), FailForMissingAdapter<SharedNested>()), 
                false, "Class field(s) without FieldAdapter: str, int");
        doTest(SharedNested("a", "x", 42), matcher(SharedNested("a", "b", 42), IgnoreMissingAdapters<SharedNested>()), 
                true, "org.matcher4cl.core.ObjectMatcherTester$SharedNested {str0: (\"a\")}");
        doTest(SharedNested("a", "x", 42), matcher(SharedNested("a", "b", 42), CreateMissingAdapters<SharedNested>()), 
                false, "<<<org.matcher4cl.core.ObjectMatcherTester$SharedNested>>> {str0: (\"a\"), str: (\"b\"/<<<\"x\">>>: expected[0]='b'(98=#62) != actual[0]='x'(120=#78)), int: (42)}");
    }
    
    shared void allNonSharedNestedLevelTests() {
        ObjectMatcher<NonSharedNested> matcher(NonSharedNested expected, MissingAdapterStrategy<NonSharedNested> strategy)  
            => ObjectMatcher<NonSharedNested> (expected, {
            FieldAdapter<NonSharedNested>(`NonSharedNested.str0`,   EqualsMatcher(expected.str0))
                }, DefaultDescriptor(), strategy);
                
        doTest(NonSharedNested("a", "b", 42), matcher(NonSharedNested("a", "b", 42), FailForMissingAdapter<NonSharedNested>()), 
                false, "Class field(s) without FieldAdapter: str, int");
        doTest(NonSharedNested("a", "b", 42), matcher(NonSharedNested("a", "b", 42), IgnoreMissingAdapters<NonSharedNested>()), 
                true, "org.matcher4cl.core.ObjectMatcherTester$NonSharedNested {str0: (\"a\")}");
        doTest(NonSharedNested("a", "b", 42), matcher(NonSharedNested("a", "b", 42), CreateMissingAdapters<NonSharedNested>()), 
                true, "org.matcher4cl.core.ObjectMatcherTester$NonSharedNested {str0: (\"a\"), str: (\"b\"), int: (42)}");
        
        doTest(NonSharedNested("a", "x", 42), matcher(NonSharedNested("a", "b", 42), FailForMissingAdapter<NonSharedNested>()), 
                false, "Class field(s) without FieldAdapter: str, int");
        doTest(NonSharedNested("a", "x", 42), matcher(NonSharedNested("a", "b", 42), IgnoreMissingAdapters<NonSharedNested>()), 
                true, "org.matcher4cl.core.ObjectMatcherTester$NonSharedNested {str0: (\"a\")}");
        doTest(NonSharedNested("a", "x", 42), matcher(NonSharedNested("a", "b", 42), CreateMissingAdapters<NonSharedNested>()), 
                false, "<<<org.matcher4cl.core.ObjectMatcherTester$NonSharedNested>>> {str0: (\"a\"), str: (\"b\"/<<<\"x\">>>: expected[0]='b'(98=#62) != actual[0]='x'(120=#78)), int: (42)}");
    }
}


test void allSharedTopLevelTests() => ObjectMatcherTester().allSharedTopLevelTests();
test void allNonSharedTopLevelTests() => ObjectMatcherTester().allNonSharedTopLevelTests();
test void allSharedNestedLevelTests() => ObjectMatcherTester().allSharedNestedLevelTests();
test void allNonSharedNestedLevelTests() => ObjectMatcherTester().allNonSharedNestedLevelTests();


// TODO: causes an NPE, report it
//test shared void createMissingAdaptersTest() {
//    
//    {FieldAdapterForDeclaration<A>*} check({FieldAdapterForDeclaration<A>*}|Description adapters) {
//        
//        if(is {FieldAdapterForDeclaration<A>*} adapters) {
//            return adapters;
//        }
//        assert (is Description adapters);
//        
//        String s = adapters.toString(SimpleDescrWriter{multiLine = true;});
//        print(s);
//        throw AssertionException(s);
//    }
//    
//    class A() {}
//    value fieldAdapters = check(CreateMissingAdapters<A>().createMissingAdapters(A(), {}, defaultResolver()));
//    
//    for(a in fieldAdapters) {
//        print(a);
//    }
//    
//    assertEquals(fieldAdapters.size, 0);
//}
//



test void allMatcherTest() {

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


test void anyMatcherTest() {

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

test void notMatcherTest() {
    
    assertTrue(NotMatcher(EqualsMatcher(42)).match(null).succeeded);  // No matcher => success
    assertEquals("Not {\"==\": ERR: non-null was expected: 42/<<<<null>>>>}", 
        dToS(NotMatcher(EqualsMatcher(42)).match(null).matchDescription));

    assertFalse(NotMatcher(EqualsMatcher(42)).match(42).succeeded);  // No matcher => success
    assertEquals("NotMatcher: child matcher succeeded {\"==\": 42}", 
        dToS(NotMatcher(EqualsMatcher(42)).match(42).matchDescription));
}

test void anythingMatcherTest() {
    
    assertTrue(AnythingMatcher().match(null).succeeded);  // No matcher => success
    assertEquals("Anything", 
        dToS(AnythingMatcher().match(null).matchDescription));
}

test void describedAsMatcherTest() {
    
    assertFalse(DescribedAsMatcher(StringDescription("Response: "), EqualsMatcher(42)).match(null).succeeded);
    assertEquals("Response: ERR: non-null was expected: 42/<<<<null>>>>", 
        dToS(DescribedAsMatcher(StringDescription("Response: "), EqualsMatcher(42)).match(null).matchDescription));
    
    assertTrue(DescribedAsMatcher(StringDescription("Response: "), EqualsMatcher(42)).match(42).succeeded);
    assertEquals("Response: 42", 
        dToS(DescribedAsMatcher(StringDescription("Response: "), EqualsMatcher(42)).match(42).matchDescription));
}

class A<T>() {
    shared actual String string = "A";
}

class MessageNode(shared String message, shared {MessageNode*} children = {}) {}

test void typeMatcherWithDescriptorTest() {
    // -- With descriptor
    class User(shared String name, shared Integer age){}
    Description messageNodeDescription(MessageNode node, String indent = "") {
        return TreeDescription(StringDescription(node.message), {for(n in node.children) messageNodeDescription(n, indent + "  ")}) ;
    }
    Descriptor descriptor = DefaultDescriptor (
        // delegate, tried first
        (Object? obj, DescriptorEnv descriptorEnv) {
            switch(obj)
            case(is User) {return "User '``obj.name``' age=``obj.age``";}
            case(is MessageNode) {
                FootNote footNote = descriptorEnv.newFootNote(messageNodeDescription(obj));
                return "MessageNode error, see [``footNote.reference``]";
            }
            else {return  null;}
        }
    );
    
    // -- Description without footnote
    assertFalse(TypeMatcher<Integer>().match("Hello").succeeded);
    assertEquals("ERR: wrong type: expected ceylon.language::String, found org.matcher4cl.core::User: <<<User 'JohnDoe' age=42>>>", 
    dToS(TypeMatcher<String>(descriptor).match(User("JohnDoe", 42)).matchDescription));
    
    // -- Description with footnote
    Description messageNodesDescr = TypeMatcher<String>(descriptor).match( MessageNode("msg0", {MessageNode("msg1"), MessageNode("msg2")}) ).matchDescription;
    StringBuilder messageNodesSb = StringBuilder();
    DefaultDescriptorEnv descriptorEnv = DefaultDescriptorEnv();
    messageNodesDescr.appendTo(messageNodesSb, SimpleDescrWriter(false /*multiLine*/), 0, descriptorEnv);
    
    // Simple message
    assertEquals("ERR: wrong type: expected ceylon.language::String, found org.matcher4cl.core::MessageNode: <<<MessageNode error, see [0]>>>", 
    messageNodesSb.string);
    
    // Footnote
    assertEquals(descriptorEnv.footNotes().size, 1);
    assert (exists FootNote footNote = descriptorEnv.footNotes().sequence[0]);
    StringBuilder footnoteSb = StringBuilder();  
    footNote.description.appendTo(footnoteSb, SimpleDescrWriter(true /*multiLine*/), 0, DefaultDescriptorEnv()/*unused*/);
    
    assertEquals("""msg0
                        msg1
                        msg2""",
        footnoteSb.string);
}

test void typeMatcherTest() {
    
    assertTrue(TypeMatcher<String>().match("Hello").succeeded);
    assertEquals("\"Hello\"", 
        dToS(TypeMatcher<String>().match("Hello").matchDescription));
    
    
    assertFalse(TypeMatcher<Integer>().match("Hello").succeeded);
    assertEquals("ERR: wrong type: expected ceylon.language::Integer, found ceylon.language::String: <<<\"Hello\">>>", 
        dToS(TypeMatcher<Integer>().match("Hello").matchDescription));
    
    assertFalse(TypeMatcher<Integer>().match(null).succeeded);
    assertEquals("ERR: wrong type: expected ceylon.language::Integer, found <null>: <<<<null>>>>", 
        dToS(TypeMatcher<Integer>().match(null).matchDescription));
    
    
    assertTrue(TypeMatcher<Sequence<Integer>>().match({1,2,3}).succeeded);
    assertEquals("[1, 2, 3]", 
        dToS(TypeMatcher<Sequence<Integer>>().match({1,2,3}).matchDescription));
    
    assertFalse(TypeMatcher<Sequence<Integer>>().match("Hello").succeeded);
    assertEquals("ERR: wrong type: expected ceylon.language::Sequence<ceylon.language::Integer>, found ceylon.language::String: <<<\"Hello\">>>", 
        dToS(TypeMatcher<Sequence<Integer>>().match("Hello").matchDescription));

        
    assertFalse(TypeMatcher<A<Integer>>().match(A<String>()).succeeded);
        assertEquals("ERR: wrong type: expected org.matcher4cl.core::A<ceylon.language::Integer>, found org.matcher4cl.core::A<ceylon.language::String>: <<<A>>>", 
        dToS(TypeMatcher<A<Integer>>().match(A<String>()).matchDescription));
    
    assertTrue(TypeMatcher<A<Integer>>().match(A<Integer>()).succeeded);
    assertEquals("A", 
        dToS(TypeMatcher<A<Integer>>().match(A<Integer>()).matchDescription));
    
    // Inheritance
    assertTrue(TypeMatcher<Object>().match(A<Integer>()).succeeded);
    assertEquals("A", 
        dToS(TypeMatcher<Object>().match(A<Integer>()).matchDescription));
    
   
}

test void notNullMatcherTest() {
    
    assertTrue(NotNullMatcher().match("Hello").succeeded);
    assertEquals("\"Hello\"", 
        dToS(NotNullMatcher().match("Hello").matchDescription));
    
    assertFalse(NotNullMatcher().match(null).succeeded);
    assertEquals("ERR: wrong type: expected ceylon.language::Object, found <null>: <<<<null>>>>",
        dToS(NotNullMatcher().match(null).matchDescription));
}

test void sameInstanceMatcherTest() {
    A<Integer> a0 = A<Integer>();
    A<Integer> a1 = A<Integer>();
     
    assertTrue(IdentifiableMatcher(a0).match(a0).succeeded);
    assertEquals("A", 
        dToS(IdentifiableMatcher(a0).match(a0).matchDescription));

    assertFalse(IdentifiableMatcher(a0).match(a1).succeeded);
    assertEquals("<<<'==='>>>A/<<<A>>>", 
        dToS(IdentifiableMatcher(a0).match(a1).matchDescription));
    
    assertFalse(IdentifiableMatcher(a0).match(12).succeeded);
    assertEquals("ERR: org.matcher4cl.core.A was expected, found ceylon.language.Integer: A/<<<12>>>", 
        dToS(IdentifiableMatcher(a0).match(12).matchDescription));
    
    assertFalse(IdentifiableMatcher(a0).match(null).succeeded);
    assertEquals("ERR: non-null was expected: A/<<<<null>>>>", 
        dToS(IdentifiableMatcher(a0).match(null).matchDescription));
}

// TODO: remove
Description? approxComparator(Float relativeError)(Float expected, Float actual) {
    if( (expected * (1-relativeError) <= actual <= expected * (1+relativeError)) ||
            (actual * (1-relativeError) <= expected <= actual * (1+relativeError))) {
        return null;
    } else {
        // Error message
        return StringDescription("== within ``relativeError*100``% : ", highlighted);
    }
}

test void simpleValuesMatcherTest() {
    class FloatMatcher(
        Float expected,
        Float relativeError, 
        Descriptor descriptor = DefaultDescriptor()
    
    ) extends EqualsOpMatcher<Float>(
        expected,
        approxComparator(relativeError)
        // TODO: restore
        //function (Float expected, Float actual) {
        //    // Compare with error margin
        //    if( (expected * (1-relativeError) <= actual <= expected * (1+relativeError)) || 
        //        (actual * (1-relativeError) <= expected <= actual * (1+relativeError))) {
        //        return null;
        //    } else {
        //        // Error message
        //        return StringDescription("== within ``relativeError*100``% : ", highlighted);
        //    }
        //}
        ,
        "== within ``expected`` ", 
        descriptor){}
        
    assertFalse(FloatMatcher(1.0, 0.0001).match(0.999).succeeded);
    assertEquals("<<<== within 0.01% : >>>1.0/<<<0.999>>>", 
        dToS(FloatMatcher(1.0, 0.0001).match(0.999).matchDescription));

    assertTrue(FloatMatcher(1.0, 0.0001).match(0.9999).succeeded);
    assertEquals("1.0/0.9999", 
        dToS(FloatMatcher(1.0, 0.0001).match(0.9999).matchDescription));
    
}

test void stringMatcherTest() {
        
    assertTrue(StringMatcher("Hello").match("Hello").succeeded);
    assertTrue(StringMatcher("").match("").succeeded);

    
    assertTrue(StringMatcher("a").match("ab").failed);
    assertEquals("\"a\"/<<<\"ab\">>> Sizes: actual=2 != expected=1", 
        dToS(StringMatcher("a").match("ab").matchDescription));

    assertTrue(StringMatcher("ab").match("a").failed);
    assertEquals("\"ab\"/<<<\"a\">>> Sizes: actual=1 != expected=2", 
        dToS(StringMatcher("ab").match("a").matchDescription));

    assertTrue(StringMatcher("ab").match("acd").failed);
    assertEquals("\"ab\"/<<<\"acd\">>> Sizes: actual=3 != expected=2: expected[1]='b'(98=#62) != actual[1]='c'(99=#63)", 
        dToS(StringMatcher("ab").match("acd").matchDescription));

    assertTrue(StringMatcher("ab").match(null).failed);
    assertEquals("A String was expected, found null: \"ab\"/<<<<null>>>>", 
        dToS(StringMatcher("ab").match(null).matchDescription));

    assertTrue(StringMatcher("ab").match(42).failed);
    assertEquals("A String was expected, found ceylon.language.Integer: \"ab\"/<<<42>>>", 
        dToS(StringMatcher("ab").match(42).matchDescription));

    
    assertFalse(StringMatcher("Hello").match("World").succeeded);
    assertEquals("\"Hello\"/<<<\"World\">>>: expected[0]='H'(72=#48) != actual[0]='W'(87=#57)", 
        dToS(StringMatcher("Hello").match("World").matchDescription));
   
    assertEquals("\"aaaHello\"/<<<\"aaaWorld\">>>: expected[3]='H'(72=#48) != actual[3]='W'(87=#57)", 
        dToS(StringMatcher("aaaHello").match("aaaWorld").matchDescription));
   
    assertEquals("\"a b\"/<<<\"a\{#00A0}b\">>>: expected[1]=' '(32=#20) != actual[1]=' '(160=#a0)", // NB: #00A0 is nbsp 
        dToS(StringMatcher("a b").match("a\{#00A0}b").matchDescription));
   
    // With conversion
    assertFalse(StringMatcher("hello", (String s) => s.uppercased).match("he llo").succeeded);
    assertTrue(StringMatcher("hello", (String s) => s.uppercased).match("hello").succeeded);
    assertTrue(StringMatcher("hello", (String s) => s.uppercased).match("HELLO").succeeded);
    assertTrue(StringMatcher("HELLO", (String s) => s.uppercased).match("hello").succeeded);
   
}

//test void dummyTest() {
//    throw Exception(" ******************************************************************************************************** ");
//}