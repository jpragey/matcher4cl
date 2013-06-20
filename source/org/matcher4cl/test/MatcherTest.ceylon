import ceylon.test { assertTrue, assertFalse, assertEquals, TestRunner, PrintingTestListener }
import org.matcher4cl.core{ EqualsMatcher, ListMatcher, MapMatcher, ObjectMatcher, FieldAdapter, Is, AllMatcher, AnyMatcher, NotMatcher, TypeMatcher, DescribedAsMatcher, StringDescription, normalStyle, AnythingMatcher, NotNullMatcher, IdentifiableMatcher, EqualsOpMatcher, DefaultDescriptor, Descriptor, highlighted, StringMatcher, MissingAdapterStrategy, FailForMissingAdapter, IgnoreMissingAdapters, CreateMissingAdapters }

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
    assertEquals("<<<An iterator was expected, found ceylon.language::Integer>>> value = 42", dToS(ListMatcher([10, 11, 12]).match(42).matchDescription)); // TODO: better expr
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


shared class AAA(shared String name, shared Integer age) {}
shared class TestClass0(name, age) {shared String name; shared Integer age;}

void objectMatcherTest() {
//    class TestClass0(name, age) {shared String name; shared Integer age;}
    TestClass0 expected = TestClass0("John", 20);
    {FieldAdapter<TestClass0> *} aFieldMatchers = {
        FieldAdapter<TestClass0>("name", EqualsMatcher(expected.name), (TestClass0 actual)=>actual.name),
        FieldAdapter<TestClass0>("age", EqualsMatcher(expected.age), (TestClass0 actual)=>actual.age)
    };
        
    ObjectMatcher<TestClass0> objectMatcher = ObjectMatcher<TestClass0> (expected, aFieldMatchers);

    assertTrue(objectMatcher.match(TestClass0("John", 20)).succeeded);
    
    assertFalse(objectMatcher.match(TestClass0("Ted", 30)).succeeded);
    assertEquals("<<<TestClass0>>> {name: ('=='\"John\"/<<<\"Ted\">>>), age: ('=='20/<<<30>>>)}", 
        dToS(objectMatcher.match(TestClass0("Ted", 30)).matchDescription));
    
    // -- Wrong field list 
    ObjectMatcher<TestClass0> tooManyAdaptersObjectMatcher = ObjectMatcher<TestClass0> (expected, {
        FieldAdapter<TestClass0>("name",   EqualsMatcher(expected.name), (TestClass0 actual)=>actual.name),
        FieldAdapter<TestClass0>("age",    EqualsMatcher(expected.age), (TestClass0 actual)=>actual.age),
        FieldAdapter<TestClass0>("gotcha", AnythingMatcher(), (TestClass0 actual)=>null)
    });
    assertFalse(tooManyAdaptersObjectMatcher.match(TestClass0("Ted", 30)).succeeded);
    assertEquals("ObjectMatcher<org.matcher4cl.test::TestClass0>: FieldAdapter list and class fields don't match.FieldAdapter(s) without class fields: gotcha", 
        dToS(tooManyAdaptersObjectMatcher.match(TestClass0("Ted", 30)).matchDescription));
    
}

shared class SharedTopLevel(shared String str0, shared String str, shared Integer int) {}

class NonSharedTopLevel    (shared String str0, shared String str, shared Integer int) {}

/*                      shared TopLevel         non-shared TopLevel     shared Nested         non-shared Nested
FailForMissingAdapter         OK                      -                      -                      OK
IgnoreMissingAdapters         OK                      OK                     OK                     OK
CreateMissingAdapters         OK                      -                      -                      -
*/

shared class ObjectMatcherTester() {
    shared class SharedNested(shared String str0, shared String str, shared Integer int) {}
    class     NonSharedNested(shared String str0, shared String str, shared Integer int) {}
    
    void doTest<T>(Object actual, ObjectMatcher<T> matcher, Boolean matchResult, String msg) given T satisfies Object {
        assertEquals(matchResult, matcher.match(actual).succeeded);
        assertEquals(msg, dToS(matcher.match(actual).matchDescription));
    }
    
    shared void allSharedTopLevelTests() {
        ObjectMatcher<SharedTopLevel> matcher(SharedTopLevel expected, MissingAdapterStrategy<SharedTopLevel> strategy)  
            => ObjectMatcher<SharedTopLevel> (expected, {
                    FieldAdapter<SharedTopLevel>("str0",   EqualsMatcher(expected.str0), (SharedTopLevel actual)=>actual.str0)
                }, DefaultDescriptor(), strategy);
                
        // SharedTopLevel
        doTest(SharedTopLevel("a", "b", 42), matcher(SharedTopLevel("a", "b", 42), FailForMissingAdapter<SharedTopLevel>()), 
                false, "Class field(s) without FieldAdapter: str, int");
        doTest(SharedTopLevel("a", "b", 42), matcher(SharedTopLevel("a", "b", 42), IgnoreMissingAdapters<SharedTopLevel>()), 
                true, "SharedTopLevel {str0: (\"a\")}");
        doTest(SharedTopLevel("a", "b", 42), matcher(SharedTopLevel("a", "b", 42), CreateMissingAdapters<SharedTopLevel>()), 
                true, "SharedTopLevel {str0: (\"a\"), str: (\"b\"), int: (42)}");
        
        doTest(SharedTopLevel("a", "x", 42), matcher(SharedTopLevel("a", "b", 42), FailForMissingAdapter<SharedTopLevel>()), 
                false, "Class field(s) without FieldAdapter: str, int");
        doTest(SharedTopLevel("a", "x", 42), matcher(SharedTopLevel("a", "b", 42), IgnoreMissingAdapters<SharedTopLevel>()), 
                true, "SharedTopLevel {str0: (\"a\")}");
        doTest(SharedTopLevel("a", "x", 42), matcher(SharedTopLevel("a", "b", 42), CreateMissingAdapters<SharedTopLevel>()), 
                false, "<<<SharedTopLevel>>> {str0: (\"a\"), str: (\"b\"/<<<\"x\">>>: expected[0]='b'(98=#62) != actual[0]='x'(120=#78)), int: (42)}");

    }
    
    shared void allNonSharedTopLevelTests() {
        ObjectMatcher<NonSharedTopLevel> matcher(NonSharedTopLevel expected, MissingAdapterStrategy<NonSharedTopLevel> strategy)  
            => ObjectMatcher<NonSharedTopLevel> (expected, {
                    FieldAdapter<NonSharedTopLevel>("str0",   EqualsMatcher(expected.str0), (NonSharedTopLevel actual)=>actual.str0)
                }, DefaultDescriptor(), strategy);
                
        // NonSharedTopLevel
        doTest(NonSharedTopLevel("a", "b", 42), matcher(NonSharedTopLevel("a", "b", 42), FailForMissingAdapter<NonSharedTopLevel>()), 
                false, "Problem getting a MH for constructor for: class org.matcher4cl.test.NonSharedTopLevelA RuntimeException occured while getting expected type declaration. Note that ObjectMatcher with FailForMissingAdapter strategy only supports top-level shared classes (Ceylon current limitation).In this case, consider using IgnoreMissingAdapters and defining adapters for all fields.");
        doTest(NonSharedTopLevel("a", "b", 42), matcher(NonSharedTopLevel("a", "b", 42), IgnoreMissingAdapters<NonSharedTopLevel>()), 
                true, "NonSharedTopLevel {str0: (\"a\")}");
        doTest(NonSharedTopLevel("a", "b", 42), matcher(NonSharedTopLevel("a", "b", 42), CreateMissingAdapters<NonSharedTopLevel>()), 
                false, "Problem getting a MH for constructor for: class org.matcher4cl.test.NonSharedTopLevelA RuntimeException occured while getting expected type declaration. Note that ObjectMatcher with CreateMissingAdapters strategy only supports top-level shared classes (Ceylon current limitation).In this case, consider using IgnoreMissingAdapters and defining adapters for all fields.");
        
        doTest(NonSharedTopLevel("a", "x", 42), matcher(NonSharedTopLevel("a", "b", 42), FailForMissingAdapter<NonSharedTopLevel>()), 
                false, "Problem getting a MH for constructor for: class org.matcher4cl.test.NonSharedTopLevelA RuntimeException occured while getting expected type declaration. Note that ObjectMatcher with FailForMissingAdapter strategy only supports top-level shared classes (Ceylon current limitation).In this case, consider using IgnoreMissingAdapters and defining adapters for all fields.");
        doTest(NonSharedTopLevel("a", "x", 42), matcher(NonSharedTopLevel("a", "b", 42), IgnoreMissingAdapters<NonSharedTopLevel>()), 
                true, "NonSharedTopLevel {str0: (\"a\")}");
        doTest(NonSharedTopLevel("a", "x", 42), matcher(NonSharedTopLevel("a", "b", 42), CreateMissingAdapters<NonSharedTopLevel>()), 
                false, "Problem getting a MH for constructor for: class org.matcher4cl.test.NonSharedTopLevelA RuntimeException occured while getting expected type declaration. Note that ObjectMatcher with CreateMissingAdapters strategy only supports top-level shared classes (Ceylon current limitation).In this case, consider using IgnoreMissingAdapters and defining adapters for all fields.");

    }
    
    shared void allSharedNestedLevelTests() {
        ObjectMatcher<SharedNested> matcher(SharedNested expected, MissingAdapterStrategy<SharedNested> strategy)  
            => ObjectMatcher<SharedNested> (expected, {
                    FieldAdapter<SharedNested>("str0",   EqualsMatcher(expected.str0), (SharedNested actual)=>actual.str0)
                }, DefaultDescriptor(), strategy);
                
        // SharedNested
        doTest(SharedNested("a", "b", 42), matcher(SharedNested("a", "b", 42), FailForMissingAdapter<SharedNested>()), 
                false, "cannot convert MethodHandle(ObjectMatcherTester,String,String,long)SharedNested to (String,String,long)ObjectA RuntimeException occured while getting expected type declaration. Note that ObjectMatcher with FailForMissingAdapter strategy only supports top-level shared classes (Ceylon current limitation).In this case, consider using IgnoreMissingAdapters and defining adapters for all fields.");
        doTest(SharedNested("a", "b", 42), matcher(SharedNested("a", "b", 42), IgnoreMissingAdapters<SharedNested>()), 
                true, "SharedNested {str0: (\"a\")}");
        doTest(SharedTopLevel("a", "b", 42), matcher(SharedNested("a", "b", 42), CreateMissingAdapters<SharedNested>()), 
                false, "cannot convert MethodHandle(ObjectMatcherTester,String,String,long)SharedNested to (String,String,long)ObjectA RuntimeException occured while getting expected type declaration. Note that ObjectMatcher with CreateMissingAdapters strategy only supports top-level shared classes (Ceylon current limitation).In this case, consider using IgnoreMissingAdapters and defining adapters for all fields.");
        
        doTest(SharedNested("a", "x", 42), matcher(SharedNested("a", "b", 42), FailForMissingAdapter<SharedNested>()), 
                false, "cannot convert MethodHandle(ObjectMatcherTester,String,String,long)SharedNested to (String,String,long)ObjectA RuntimeException occured while getting expected type declaration. Note that ObjectMatcher with FailForMissingAdapter strategy only supports top-level shared classes (Ceylon current limitation).In this case, consider using IgnoreMissingAdapters and defining adapters for all fields.");
        doTest(SharedNested("a", "x", 42), matcher(SharedNested("a", "b", 42), IgnoreMissingAdapters<SharedNested>()), 
                true, "SharedNested {str0: (\"a\")}");
        doTest(SharedNested("a", "x", 42), matcher(SharedNested("a", "b", 42), CreateMissingAdapters<SharedNested>()), 
                false, "cannot convert MethodHandle(ObjectMatcherTester,String,String,long)SharedNested to (String,String,long)ObjectA RuntimeException occured while getting expected type declaration. Note that ObjectMatcher with CreateMissingAdapters strategy only supports top-level shared classes (Ceylon current limitation).In this case, consider using IgnoreMissingAdapters and defining adapters for all fields.");
    }
    
    shared void allNonSharedNestedLevelTests() {
        ObjectMatcher<NonSharedNested> matcher(NonSharedNested expected, MissingAdapterStrategy<NonSharedNested> strategy)  
            => ObjectMatcher<NonSharedNested> (expected, {
                    FieldAdapter<NonSharedNested>("str0",   EqualsMatcher(expected.str0), (NonSharedNested actual)=>actual.str0)
                }, DefaultDescriptor(), strategy);
                
        // NonSharedNested
        doTest(NonSharedNested("a", "b", 42), matcher(NonSharedNested("a", "b", 42), FailForMissingAdapter<NonSharedNested>()), 
                false, "Class field(s) without FieldAdapter: str, int");
        doTest(NonSharedNested("a", "b", 42), matcher(NonSharedNested("a", "b", 42), IgnoreMissingAdapters<NonSharedNested>()), 
                true, "NonSharedNested {str0: (\"a\")}");
        doTest(NonSharedNested("a", "b", 42), matcher(NonSharedNested("a", "b", 42), CreateMissingAdapters<NonSharedNested>()), 
                false, "Failed to find getter method getStr for: JavaBeanValue[str:String]A RuntimeException occured while getting field str of expected object of type NonSharedNested. Note that ObjectMatcher with CreateMissingAdapters strategy only supports top-level shared classes (Ceylon current limitation).In this case, consider using IgnoreMissingAdapters and defining adapters for all fields.");
        
        doTest(NonSharedNested("a", "x", 42), matcher(NonSharedNested("a", "b", 42), FailForMissingAdapter<NonSharedNested>()), 
                false, "Class field(s) without FieldAdapter: str, int");
        doTest(NonSharedNested("a", "x", 42), matcher(NonSharedNested("a", "b", 42), IgnoreMissingAdapters<NonSharedNested>()), 
                true, "NonSharedNested {str0: (\"a\")}");
        doTest(NonSharedNested("a", "x", 42), matcher(NonSharedNested("a", "b", 42), CreateMissingAdapters<NonSharedNested>()), 
                false, "Failed to find getter method getStr for: JavaBeanValue[str:String]A RuntimeException occured while getting field str of expected object of type NonSharedNested. Note that ObjectMatcher with CreateMissingAdapters strategy only supports top-level shared classes (Ceylon current limitation).In this case, consider using IgnoreMissingAdapters and defining adapters for all fields.");
    }
    
     
}

shared void objectMatcherWithMissingAdaptersTest() {
    ObjectMatcherTester().allSharedTopLevelTests();
    ObjectMatcherTester().allNonSharedTopLevelTests();
    ObjectMatcherTester().allSharedNestedLevelTests();
    ObjectMatcherTester().allNonSharedNestedLevelTests();
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
                return StringDescription("== within ``relativeError*100``% : ", highlighted);
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

void stringMatcherTest() {
        
    assertTrue(StringMatcher("Hello").match("Hello").succeeded);
    assertTrue(StringMatcher("").match("").succeeded);

    
    assertTrue(StringMatcher("a").match("ab").failed());
    assertEquals("\"a\"/<<<\"ab\">>> Sizes: actual=2 != expected=1", 
        dToS(StringMatcher("a").match("ab").matchDescription));

    assertTrue(StringMatcher("ab").match("a").failed());
    assertEquals("\"ab\"/<<<\"a\">>> Sizes: actual=1 != expected=2", 
        dToS(StringMatcher("ab").match("a").matchDescription));

    assertTrue(StringMatcher("ab").match(null).failed());
    assertEquals("ERR: non-null was expected: \"ab\"/<<<<null>>>>", 
        dToS(StringMatcher("ab").match(null).matchDescription));

    assertTrue(StringMatcher("ab").match(42).failed());
    assertEquals("ERR: a String was expected, found ceylon.language::Integer: \"ab\"/<<<42>>>", 
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

void matcherTestSuite0() {
    equalsMatcherTest();
    listMatcherTest(); 
    mapMatcherTest();
    objectMatcherTest();
    allMatcherTest();
    anyMatcherTest();
    notMatcherTest();
    anythingMatcherTest();
    describedAsMatcherTest();
    typeMatcherTest();
    sameInstanceMatcherTest();
    simpleValuesMatcherTest();
    stringMatcherTest();
}

void matcherTestSuite() {
    TestRunner testRunner = TestRunner();
    testRunner.addTestListener(PrintingTestListener());

    testRunner.addTest("org.jpr.matchers.core::equalsMatcherTest", equalsMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::listMatcherTest", listMatcherTest); 
    testRunner.addTest("org.jpr.matchers.core::mapMatcherTest", mapMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::objectMatcherTest", objectMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::objectMatcherWithMissingAdaptersTest", objectMatcherWithMissingAdaptersTest);
    testRunner.addTest("org.jpr.matchers.core::allMatcherTest", allMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::anyMatcherTest", anyMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::notMatcherTest", notMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::anythingMatcherTest", anythingMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::describedAsMatcherTest", describedAsMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::typeMatcherTest", typeMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::sameInstanceMatcherTest", sameInstanceMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::notNullMatcherTest", notNullMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::simpleValuesMatcherTest", simpleValuesMatcherTest);
    testRunner.addTest("org.jpr.matchers.core::stringMatcherTest", stringMatcherTest);
    
    testRunner.run();
    
}

