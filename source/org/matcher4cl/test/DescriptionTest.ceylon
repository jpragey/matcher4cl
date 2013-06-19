import ceylon.test { assertEquals }
import org.matcher4cl.core{ ListDescription, Description, TextFormat, SimpleTextFormat, ValueDescription, normalStyle, highlighted, MatchDescription, MapDescription, MapEntryDescription, StringDescription, ObjectFieldDescription, ObjectDescription, DescriptorEnv, DefaultDescriptorEnv }


String dToS(Description description, TextFormat descriptionWriter = SimpleTextFormat(false /*multiLine*/)) {
    StringBuilder sb = StringBuilder();
    DescriptorEnv descriptorEnv = DefaultDescriptorEnv();
    description.appendTo(sb, descriptionWriter, 0, descriptorEnv);
    String s = sb.string;
    return s;
}

"ValueDescription test."
void valueDescriptionTest() {
 
    assertEquals("\"hello\"", dToS(ValueDescription(normalStyle, "hello")));
    assertEquals("<<<\"hello\">>>", dToS(ValueDescription(highlighted, "hello")));

    assertEquals("<null>", dToS(ValueDescription(normalStyle /*errorStyle*/, null)));
    assertEquals("<<<<null>>>>", dToS(ValueDescription(highlighted /*errorStyle*/, null)));

    assertEquals("42", dToS(ValueDescription(normalStyle /*errorStyle*/, 42)));
    assertEquals("<<<42>>>", dToS(ValueDescription(highlighted /*errorStyle*/, 42)));
}

"ValueDescription test."
void matchDescriptionTest() {

    assertEquals("43/<<<42>>>", dToS(MatchDescription(null, highlighted /*matched*/, 43 /*Object? actualObj*/, 42/*Object? expectedObj*/)));
    assertEquals("42/<<<42>>>", dToS(MatchDescription(null, highlighted /*matched*/, 42 /*Object? actualObj*/, 42/*Object? expectedObj*/)));
    assertEquals("43/42", dToS(MatchDescription(null, normalStyle /*matched*/, 43 /*Object? actualObj*/, 42/*Object? expectedObj*/)));
    assertEquals("42", dToS(MatchDescription(null, normalStyle /*matched*/, 42 /*Object? actualObj*/, 42/*Object? expectedObj*/)));

    assertEquals("<null>/<<<<null>>>>", dToS(MatchDescription(null, highlighted /*matched*/, null, null)));

    assertEquals("ERR @2: 43/<<<42>>>", dToS(MatchDescription(
        StringDescription("ERR @``2``: ", normalStyle)
        , highlighted, 43 /*Object? actualObj*/, 42/*Object? expectedObj*/)));
}


"ListDescription test."
void listDescriptionTest() {
    assertEquals("{43/<<<42>>>, 1.999/2, 2}", dToS(ListDescription(null /*failure*/, [
        MatchDescription(null, highlighted , 43, 42), MatchDescription(null, normalStyle, 1.999, 2), MatchDescription(null, normalStyle, 2, 2)])));
    
    assertEquals("ERR: elements don't match:  {@0: 43/<<<42>>>, 1.999/2, 2}", dToS(ListDescription(
        StringDescription("ERR: elements don't match: "), [
            MatchDescription(StringDescription("@``0``: "), highlighted , 43, 42), 
            MatchDescription(null, normalStyle, 1.999, 2), 
            MatchDescription(null, normalStyle, 2, 2)])));
    
    assertEquals("ERR: list size mismatch: 3 expected, 1 actuals:  {43/<<<42>>>} => ERR 2 expected not in actual list:  {<<<100>>>, 101}", 
            dToS(ListDescription(
            StringDescription("ERR: list size mismatch: ``3`` expected, ``1`` actuals: "), 
            [MatchDescription(null, highlighted , 43, 42)],
            [ValueDescription(highlighted, 100), ValueDescription(normalStyle, 101)],
            []
    
    )));
    assertEquals("ERR: list size mismatch: 1 expected, 3 actuals:  {43/<<<42>>>} => ERR 2 actual not in expected list:  {<<<100>>>, 101}", 
            dToS(ListDescription(
            StringDescription("ERR: list size mismatch: ``1`` expected, ``3`` actuals: "), 
            [MatchDescription(null, highlighted , 43, 42)],
            [],
            [ValueDescription(highlighted, 100), ValueDescription(normalStyle, 101)]    
    )));
    
    
    // -- Multiline
    TextFormat mldw = SimpleTextFormat(true /*multiLine*/);
    assertEquals("ERR: list size mismatch: 1 expected, 3 actuals:  {43/<<<42>>>}
                   => ERR 2 actual not in expected list:  {<<<100>>>, 101}", 
            dToS(ListDescription(
            StringDescription("ERR: list size mismatch: ``1`` expected, ``3`` actuals: "), 
            [MatchDescription(null, highlighted , 43, 42)],
            [],
            [ValueDescription(highlighted, 100), ValueDescription(normalStyle, 101)]    
    ), mldw));
    
    
}

"ListDescription test."
void listDescriptionTest_Tmp2() {
    // -- Multiline
    TextFormat mldw = SimpleTextFormat(true /*multiLine*/);
    assertEquals("ERR: list size mismatch: 1 expected, 3 actuals:  {43/<<<42>>>}
                  ERR 2 actual not in expected list:  {<<<100>>>, 101}",
                   
            dToS(ListDescription(
            StringDescription("ERR: list size mismatch: ``1`` expected, ``3`` actuals: "), 
            [MatchDescription(null, highlighted , 43, 42)],
            [],
            [ValueDescription(highlighted, 100), ValueDescription(normalStyle, 101)]    
    ), mldw));
}

"ListDescription test."
void listDescriptionTest_Tmp() {
    // -- Multiline
    TextFormat mldw = SimpleTextFormat(true /*multiLine*/);
    
    assertEquals("", 
            dToS(ListDescription(
            StringDescription("ERR: list size mismatch: ``1`` expected, ``3`` actuals: "), 
            [
                ListDescription(null, [MatchDescription(null, highlighted , 43, 42), MatchDescription(null, highlighted , 42, 42), MatchDescription(null, highlighted , 42, 42)]),
                ListDescription(null, [MatchDescription(null, highlighted , 43, 42), MatchDescription(null, highlighted , 42, 42)]),
                ListDescription(null, [MatchDescription(null, highlighted , 43, 42), MatchDescription(null, highlighted , 42, 42)])
            ],
            [
                ListDescription(null, [MatchDescription(null, highlighted , 43, 42), MatchDescription(null, highlighted , 42, 42)]),
                ListDescription(null, [MatchDescription(null, highlighted , 43, 42), MatchDescription(null, highlighted , 42, 42)]),
                ListDescription(null, [MatchDescription(null, highlighted , 43, 42), MatchDescription(null, highlighted , 42, 42)])
            ],
            [
                ListDescription(null, [MatchDescription(null, highlighted , 43, 42), MatchDescription(null, highlighted , 42, 42)]),
                ListDescription(null, [MatchDescription(null, highlighted , 43, 42), MatchDescription(null, highlighted , 42, 42)]),
                ListDescription(null, [MatchDescription(null, highlighted , 43, 42), MatchDescription(null, highlighted , 42, 42)])
            ]
    ), mldw));
}

"FormattedDescription test."
void mapEntryDescriptionTest() {
    assertEquals("\"hello\"->43/<<<42>>>", dToS(MapEntryDescription(
        ValueDescription(normalStyle, "hello"), 
        MatchDescription(null, highlighted , 43, 42))));
}

"ListDescription test."
void mapDescriptionTest() {
    
    assertEquals("{\"k0\"->42, \"k1\"->43, \"k2\"->44}", dToS(MapDescription(null /*failure*/, [
        MapEntryDescription(ValueDescription(normalStyle /*errorStyle*/, "k0"), MatchDescription(null, normalStyle , 42, 42)),
        MapEntryDescription(ValueDescription(normalStyle /*errorStyle*/, "k1"), MatchDescription(null, normalStyle , 43, 43)),
        MapEntryDescription(ValueDescription(normalStyle /*errorStyle*/, "k2"), MatchDescription(null, normalStyle , 44, 44))
        ])));

                  
    assertEquals("<<<ERR (value(s) mismatch)>>> {\"hello\"->ERR for ==: 43/<<<42>>>}", dToS(MapDescription(
        StringDescription("ERR (value(s) mismatch)", highlighted), [
        MapEntryDescription(ValueDescription(normalStyle /*errorStyle*/, "hello"), MatchDescription(StringDescription("ERR for ==: "), highlighted , 43, 42))
        ])));

    assertEquals(  "<<<ERR (key sets don't match)>>> {\"k0\"->42, \"k1\"->43, \"k2\"->44} => ERR 2 actual not in expected list:  {\"ek1\"->43, \"ek2\"->44}",
        dToS(MapDescription(
        StringDescription("ERR (key sets don't match)", highlighted), [
            MapEntryDescription(ValueDescription(normalStyle /*errorStyle*/, "k0"), MatchDescription(null, normalStyle , 42, 42)),
            MapEntryDescription(ValueDescription(normalStyle /*errorStyle*/, "k1"), MatchDescription(null, normalStyle , 43, 43)),
            MapEntryDescription(ValueDescription(normalStyle /*errorStyle*/, "k2"), MatchDescription(null, normalStyle , 44, 44))
        ],
        [
            MapEntryDescription(ValueDescription(normalStyle /*errorStyle*/, "ek1"), MatchDescription(null, normalStyle , 43, 43)),
            MapEntryDescription(ValueDescription(normalStyle /*errorStyle*/, "ek2"), MatchDescription(null, normalStyle , 44, 44))
        ],
        []
        )));

    assertEquals("<<<ERR (key sets don't match)>>> {\"k0\"->42, \"k1\"->43, \"k2\"->44} => ERR 2 expected not in actual list:  {\"ak1\"->43, \"ak2\"->44}", 
        dToS(MapDescription(
        StringDescription("ERR (key sets don't match)", highlighted), [
            MapEntryDescription(ValueDescription(normalStyle /*errorStyle*/, "k0"), MatchDescription(null, normalStyle , 42, 42)),
            MapEntryDescription(ValueDescription(normalStyle /*errorStyle*/, "k1"), MatchDescription(null, normalStyle , 43, 43)),
            MapEntryDescription(ValueDescription(normalStyle /*errorStyle*/, "k2"), MatchDescription(null, normalStyle , 44, 44))
        ],
        [],
        [
            MapEntryDescription(ValueDescription(normalStyle /*errorStyle*/, "ak1"), MatchDescription(null, normalStyle , 43, 43)),
            MapEntryDescription(ValueDescription(normalStyle, "ak2"), MatchDescription(null, normalStyle , 44, 44))
        ]
        )));

    assertEquals("<<<ERR (key sets don't match)>>> {\"k0\"->42, \"k1\"->43, \"k2\"->44} => ERR 2 expected not in actual list:  {\"ek1\"->43, \"ek2\"->44} => ERR 2 actual not in expected list:  {\"ak1\"->43, \"ak2\"->44}",
        dToS(MapDescription(
        StringDescription("ERR (key sets don't match)", highlighted), [
            MapEntryDescription(ValueDescription(normalStyle, "k0"), MatchDescription(null, normalStyle , 42, 42)),
            MapEntryDescription(ValueDescription(normalStyle, "k1"), MatchDescription(null, normalStyle , 43, 43)),
            MapEntryDescription(ValueDescription(normalStyle, "k2"), MatchDescription(null, normalStyle , 44, 44))
        ],
        [
            MapEntryDescription(ValueDescription(normalStyle, "ak1"), MatchDescription(null, normalStyle , 43, 43)),
            MapEntryDescription(ValueDescription(normalStyle, "ak2"), MatchDescription(null, normalStyle , 44, 44))
        ],
        [
            MapEntryDescription(ValueDescription(normalStyle, "ek1"), MatchDescription(null, normalStyle , 43, 43)),
            MapEntryDescription(ValueDescription(normalStyle, "ek2"), MatchDescription(null, normalStyle , 44, 44))
        ]
        )));
}

"FormattedDescription test."
void objectFieldDescriptionTest() {
    assertEquals("field: (43/<<<42>>>)", dToS(ObjectFieldDescription(
        "field", 
        MatchDescription(null, highlighted , 43, 42))));
}

"ObjectDescription test."
void objectDescriptionTest() {
    assertEquals("ERR: MyClass field mismatch:  {field0: (42), field1: (43/<<<42>>>)}", dToS(
    ObjectDescription(
        StringDescription("ERR: MyClass field mismatch: "),
        [   
            ObjectFieldDescription("field0", MatchDescription(null, normalStyle , 42, 42)),
            ObjectFieldDescription("field1", MatchDescription(null, highlighted, 43, 42))
        ])));
}

void descriptionTestSuite() {
    
    valueDescriptionTest() ;
    matchDescriptionTest(); 
    listDescriptionTest(); 
    mapEntryDescriptionTest(); 
    mapDescriptionTest(); 
    objectFieldDescriptionTest(); 
    objectDescriptionTest();
}

