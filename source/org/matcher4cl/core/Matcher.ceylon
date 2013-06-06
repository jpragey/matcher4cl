
doc "Result of a [[Matcher]] match."
by "Jean-Pierre Ragey"
shared class MatcherResult(succeeded, matchDescription) {
    doc "true if match succeeded, false otherwise."
    shared Boolean succeeded;
    
    doc "Description of matched objects. It is typically a tree of [[Description]]s, where [[MatchDescription]] 
         mark simple values comparisons, and decorated by mismatch indications.
         Note that it must be present even if matching succeeded, as [[NotMatcher]] uses successful match descriptions
         as mismatch description."
    shared Description matchDescription;
    
    doc "Convenient method that returns the opposite of `succeeded`."
    shared Boolean failed() {
        return !succeeded;
    }
}

doc "Matches an actual value against some criterion (usually an 'expected' value passed to constructor)"
by "Jean-Pierre Ragey"
shared interface Matcher {
    doc "Performs the match."
    shared formal MatcherResult match(
        doc "The value to match."
        Object? actual,
        doc "Resolver: implementations may use it to get matcher for members. 
             Useful for somewhat generic class matchers, eg matchers for lists or maps."
        Matcher (Object? ) resolver = defaultMatcherResolver());
    
    doc "Short one-line description, eg 'operator =='"
    shared formal Description description(Matcher (Object? ) resolver);
}

doc "Matcher based on comparison between two simple values, like Integer or String. 
     Subclassing it is a simple way of creating custom simple values matcher.
     It delegates matching to a method with an equals-like signature:
     `Description?(T, T)`, that returns null for match, or a mismatch description.
     
     For example, you could easily create Matchers:
     - for numbers with error margin;
     - for case-insensitive Strings (or insensitive to start/end blanks);
     - for complex number (think of creating a custom [[Descriptor]] for them),
       possibly with error margin;
     etc.
     
     If your class is somewhat complex (eg it has fields), [[ObjectMatcher]] may be more appropriate. 
     "
see ("EqualsMatcher", "IdentifiableMatcher")
by "Jean-Pierre Ragey"
shared abstract class EqualsOpMatcher<T>(
    doc "The expected value"
    T? expected, 
    doc "Value comparator: returns null if first arg (expected) matches  the second arg (actual),
         otherwise return a mismatch description." 
    Description?(T, T) equals,
    doc "A short description of the matcher (eg '=='). Suggestion: add matcher parameters, eg error margin."
    String equalsDescriptionString, 
    doc "Descriptor for actual/expected values formatting"
    Descriptor descriptor = DefaultDescriptor()
    
    ) satisfies Matcher 
    given T satisfies Object
{
    
    doc "Same content as constructor `equalsDescriptionString` parameter."
    shared actual Description description(Matcher (Object? ) resolver) => ValueDescription(normalStyle, equalsDescriptionString);
    
    doc "Perform the match:
         - succeeds if both actual/expected values are null;
         - fails if only one is null;
         - fails if `actual` is not a T or a subtype of T;
         - if both are non-null, delegate matching to the `equals` constructor parameter. 
         "
    shared actual MatcherResult match(Object? actual,
        
        Matcher (Object? ) matcherResolver) {
        Boolean matched ;
        Description d;
        
        if(exists expected) {
            
            if(is T actual) {
                Description? failDescription = equals(expected, actual);
                matched = failDescription is Null;
                d = MatchDescription(failDescription, matchStyle(matched), expected, actual, descriptor);
                
            } else if(exists actual){
                matched = false;
                Description fd = StringDescription("ERR: ``className(expected)`` was expected, found ``className(actual)``: ", normalStyle);
                d = MatchDescription(fd, highlighted, expected, actual, descriptor);
            } else {
                matched = false;
                Description fd = StringDescription("ERR: non-null was expected: ", normalStyle);
                d = MatchDescription(fd, highlighted, expected, actual, descriptor);
            }
            
        } else {
            matched = actual is Null;
            
            if(matched) {
                d = MatchDescription(null, normalStyle, expected, actual, descriptor);
            } else {
                Description fd = StringDescription("ERR: <null> was expected: ", normalStyle);
                d = MatchDescription(fd, matchStyle(matched), expected, actual, descriptor);
            }
        }
          
        return MatcherResult(matched, d);
    }
}

by "Jean-Pierre Ragey"
shared class StringMatcher(
    doc "The expected value"
    String expected, 
    doc "Descriptor for actual values formatting"
    Descriptor descriptor = DefaultDescriptor()
    ) satisfies Matcher 
{
    
    doc "Same content as constructor `equalsDescriptionString` parameter."
    shared actual Description description(Matcher (Object? ) resolver) => StringDescription("StringMatcher");
    
    void appendHexChars(Integer i, StringBuilder sb) {
        
        if(i>15) {
            appendHexChars(i/16, sb);
        }
        Character? c = "0123456789abcdef"[i%16];
        assert (exists c);
        sb.appendCharacter(c);
    }
    
    String toHex(Character c) {
        Integer i = c.integer;
        StringBuilder sb = StringBuilder();
        appendHexChars(c.integer, sb);
        String s = sb.string;
        return s;
    }
    
    doc "Perform the match:
         - succeeds if both actual/expected values are null;
         - fails if only one is null;
         - fails if `actual` is not a T or a subtype of T;
         - if both are non-null, delegate matching to the `equals` constructor parameter. 
         "
    shared actual MatcherResult match(Object? actual,
        
        Matcher (Object? ) matcherResolver) {
        Boolean matched ;
        Description d;
        
            
        if(is String actual) {
            String expString = expected; 
            String actString = actual; 
            matched = expString == actString; 
            if(matched) {
                d = MatchDescription(null, normalStyle, expected, actual, descriptor);
            } else {
                
                variable Description? failDescription = null;
                if(actString.size != expString.size) {
                    failDescription = StringDescription(" Sizes: actual=``actString.size`` != expected=``expString.size``"); 
                } else {
                    Iterator<Character> expIt = expString.iterator();
                    Iterator<Character> actIt = actString.iterator();
                    variable Integer index = 0;
                    while(!is Finished a = actIt.next()) {
                        if(!is Finished e = expIt.next()) {
                            if(a != e) {
                                
                                failDescription = StringDescription(
//                                  ": first different char at [``index``]: actual=\'``a``\'(``a.integer``=#``toHex(a)``) != expected=\'``e``\'(``e.integer``=#``toHex(a)``)");
                                    ": expected[``index``]=\'``e``\'(``e.integer``=#``toHex(e)``) != actual[``index``]=\'``a``\'(``a.integer``=#``toHex(a)``)");
                                break; 
                            }
                        }
                        index++;
                    }
                }
                
                if(exists fd = failDescription) {
                    d = CatDescription({MatchDescription(null, normalStyle, expected, actual, descriptor), fd});
                } else {
                    d = MatchDescription(null, normalStyle, expected, actual, descriptor);
                    
                }
            }
            
        } else  {
            matched = false;
            Description fd;
            if(exists actual){
                fd = StringDescription("ERR: a String was expected, found ``className(actual)``: ", normalStyle);
            } else {
                fd = StringDescription("ERR: non-null was expected: ", normalStyle);
            }
            d = MatchDescription(fd, highlighted, expected, actual, descriptor);
        }    
          
        return MatcherResult(matched, d);
    }
}


doc "Matcher based on '==' comparison"
by "Jean-Pierre Ragey"
shared class EqualsMatcher(
    doc "Expected value"
    Object? expected, 
    doc "Descriptor, used to print expected/actual values if they are not equal."
    Descriptor descriptor = DefaultDescriptor()
    
    ) extends EqualsOpMatcher<Object>(
        expected, 
        function (Object expected, Object actual) {
            if(expected == actual) {return null;} 
            else {return StringDescription("'=='", normalStyle);}
         },
        "==",
        descriptor)
{
}

doc "Matcher based on '===' comparison"
by "Jean-Pierre Ragey"
shared class IdentifiableMatcher(
    doc "Expected value"
    Identifiable expected, 
    doc "Descriptor, used to print expected/actual values if they don't refer to the same instance."
    Descriptor descriptor = DefaultDescriptor()
    
    ) extends EqualsOpMatcher<Identifiable>(
        expected,
        function (Identifiable expected, Identifiable actual) {
            if(expected === actual) {return null;} 
            else {return StringDescription("'==='", highlighted);}
        },
        "===", 
        descriptor)
{}


doc "Matcher for `Iterable` values."
by "Jean-Pierre Ragey"
shared class ListMatcher(
        doc "Expected elements"
        {Object? *} expected,
        doc "Descriptor for elements decriptions " 
        Descriptor descriptor = DefaultDescriptor()
        ) satisfies Matcher 
{
    doc "\"ListMatcher\""
    shared actual Description description(Matcher (Object? ) resolver) => ValueDescription(normalStyle, "ListMatcher");
    
    doc "Actual and expected list elements are matched one by one; matchers are found by `matcherResolver`.
         It fails if `actual` is not an `Iterable`, if list lengths differ, or if any element match fails.
         "
    shared actual MatcherResult match(Object? actual,
        
        Matcher (Object? ) matcherResolver) {
        MatcherResult result;
        
        if(is Iterable<Object?> actual) {
            
            SequenceBuilder<Description> elementsDescrSb = SequenceBuilder<Description>();
            SequenceBuilder<Description> extraActualDescrSb = SequenceBuilder<Description>();
            SequenceBuilder<Description> extraExpectedDescrSb = SequenceBuilder<Description>();
            variable Integer mismatchCount = 0;
            
            Iterator<Object?> expIt = expected.iterator();
            Iterator<Object?> actIt = actual.iterator();
            variable Integer index = 0;
            while(!is Finished a = actIt.next()) {
                if(!is Finished e = expIt.next()) {
                    // -- Compare elements
                    Matcher elemMatcher = matcherResolver(e);
                    MatcherResult mr = elemMatcher.match(a, matcherResolver);
                    
                    Boolean matched = mr.succeeded;
                    variable Description md = mr.matchDescription;
                    
                    if(!matched) {  // Append element index
                        md = CatDescription{
                            StringDescription("At position ``index`` ", highlighted),
                            elemMatcher.description(matcherResolver),
                            StringDescription(": "),
                            md
                        };   
                    }
                    
                    elementsDescrSb.append(md);
                    
                    if(mr.failed()) {
                        mismatchCount++;
                    }
                    
                    
                } else {    // expected list finished before actual
                    extraActualDescrSb.append(ValueDescription(normalStyle /*error*/, a, descriptor));
                    break;
                }
                index++;
            }
            
            
            while(!is Finished e = expIt.next()) {
                extraExpectedDescrSb.append(ValueDescription(normalStyle, e, descriptor));
            }
            
            while(!is Finished a = actIt.next()) {
                extraActualDescrSb.append(ValueDescription(normalStyle, a, descriptor));
            }
            
            Description? failureDescription;
            variable Boolean succeded = false;
            if(mismatchCount > 0) {
                failureDescription = StringDescription("``mismatchCount`` mismatched:");
            } else if(! extraActualDescrSb.empty) {
                failureDescription = StringDescription("Actual list is longer than expected: ``expected.size`` expected, ``actual.size`` actual: ");
            } else if(! extraExpectedDescrSb.empty) {
                failureDescription = StringDescription("Expected list is longer than actual: ``expected.size`` expected, ``actual.size`` actual: ");
            } else {
                failureDescription = null;
                succeded = true;
            }
            
            ListDescription ld = ListDescription(failureDescription, elementsDescrSb.sequence, extraExpectedDescrSb.sequence, extraActualDescrSb.sequence);
            result = MatcherResult(succeded, ld);
            
        } else if(exists actual){
            result = MatcherResult(false, 
                CatDescription({ 
                    StringDescription("An iterator was expected, found ``className(actual)``", highlighted),
                    StringDescription(" value = ", normalStyle),
                    ValueDescription(normalStyle, actual, descriptor)
            }));
        } else {
            result = MatcherResult(false, StringDescription("An iterator was expected, found null", highlighted));
        }
        
        return result;
    }
}

doc "Matcher for `Map`s.
     Maps match if:
     - they have the same set of keys;
     - for each key, actual and expected values match.  
     "
by "Jean-Pierre Ragey"
shared class MapMatcher<Key, Item>(
        doc "Expected map"
        Map<Key, Item> expected,
        //doc "Resolver for values matching" 
        //MatcherResolver matcherResolver = DefaultMatcherResolver(),
        doc "Descriptor for both keys and simple values." 
        Descriptor descriptor = DefaultDescriptor()
        
        ) satisfies Matcher 
        given Key satisfies Object
        given Item satisfies Object
{
    
    doc "\"MapMatcher\""
    shared actual Description description(Matcher (Object? ) resolver) => ValueDescription(normalStyle, "MapMatcher");
    
    shared actual MatcherResult match(Object? actual, Matcher (Object? )  matcherResolver) {
        MatcherResult result;
        
        if(is Map<Key, Item> actual) {

            // Expected keys not in actual map
            Set<Key> extraExpectedKeys = expected.keys.complement(actual.keys);
            MapEntryDescription[] extraExpected = extraExpectedKeys.collect((Key key) => MapEntryDescription(
                ValueDescription(normalStyle /*error*/, key, descriptor), 
                MatchDescription(null, normalStyle, expected.get(key), null /*actualObj*/, descriptor, true /*writeExpected*/, false /* writeActual*/)));
            
            // Actual keys not in expected map
            Set<Key> extraActualKeys = actual.keys.complement(expected.keys);
            MapEntryDescription[] extraActual = extraActualKeys.collect((Key key) => MapEntryDescription(
                ValueDescription(normalStyle /*error*/, key, descriptor), 
                MatchDescription(null, normalStyle, null, actual.get(key), descriptor, false /*writeExpected*/, true /* writeActual*/)));
            
            // Common elements
            variable Integer mismatchCount = 0;
            SequenceBuilder<MapEntryDescription> elementsDescrSb = SequenceBuilder<MapEntryDescription>();
            
            Set<Key> commonKeys = actual.keys.intersection(expected.keys);
            for(key in commonKeys) {
                Item? actualItem = actual.get(key);
                Item? expectedItem = expected.get(key);
                Matcher itemMatcher = matcherResolver(expectedItem);
                
                MatcherResult mr = itemMatcher.match(actualItem, matcherResolver);
                
                Boolean matched = mr.succeeded;
                variable Description? prefix = null;
                
                if(!matched) {
                    prefix = CatDescription{
                        StringDescription("Value mismatch for "),
                        itemMatcher.description(matcherResolver),
                        StringDescription(": ", highlighted)
                    };   
                }
                
                MatchDescription md = MatchDescription(prefix, matchStyle(matched), expectedItem, actualItem, descriptor);
                MapEntryDescription med = MapEntryDescription(ValueDescription(normalStyle, key, descriptor), md);
                
                elementsDescrSb.append(med);
                
                if(mr.failed()) {
                    mismatchCount++;
                }
            }
            
            Description? failureDescription;
            variable Boolean succeded = false;
            if(mismatchCount > 0) {
                failureDescription = StringDescription("``mismatchCount`` values mismatched:");
            } else if(! extraActual.empty) {
                failureDescription = StringDescription("Actual map is longer than expected: ``expected.size`` expected, ``actual.size`` actual: ");
            } else if(! extraExpected.empty) {
                failureDescription = StringDescription("Expected map is longer than actual: ``expected.size`` expected, ``actual.size`` actual: ");
            } else {
                failureDescription = null;
                succeded = true;
            }
            
            MapDescription ld = MapDescription(failureDescription, elementsDescrSb.sequence, extraExpected.sequence, extraActual.sequence/*, descriptor*/);
            result = MatcherResult(succeded, ld);
            
        } else if(exists actual){
            result = MatcherResult(false, StringDescription("A Map was expected, found ``className(actual)``", highlighted));
        } else {
            result = MatcherResult(false, StringDescription("A Map was expected, found null", highlighted));
        }
        
        return result;
    }
}

doc "Adapter for a custom class T field, to by used with [[ObjectMatcher]].
     The field of actual value is returned by `field()`; a matcher for it is returned by `matcher()`.
     "
see "ObjectMatcher"     
by "Jean-Pierre Ragey"
shared class FieldAdapter<T>(
    doc "Class field name, for description"
    shared String fieldName,
    doc "Return a matcher for the expected field of `expected`"
    shared Matcher (T) matcher,
    doc "Return the value of the field of `actual`"
    shared Object? (T) field
    ) 
    given T satisfies Object
{
}

doc "Custom class matcher.
     It checks if actual value is a T (or a subtype of),
     then use a list of [[FieldAdapter]] to get matchers for its fields and the fields themselves;
     match succeeds if all field matchers succeed.
     "
by "Jean-Pierre Ragey"
shared class ObjectMatcher<T> (
        doc "The expected object."
        T expected,
        doc "Adapters for each field, to get actual objects fields and field matchers."
        {FieldAdapter<T> *} fieldMatchers,
        doc "Descriptor used to describe actual value, if its type doesn't describe the expected one.'"
        Descriptor descriptor = DefaultDescriptor()
        ) satisfies Matcher 
        given T satisfies Object
{
    doc "\"ObjectMatcher\" (subject to change, may include T name in future)"
    shared actual Description description(Matcher (Object? ) resolver) => StringDescription("ObjectMatcher", normalStyle); 
    
    String simpleClassName(Object obj) {
        String cn = className(obj); 
        return cn.split(":", true, true).last else cn;
    }
    
    shared actual MatcherResult match(Object? actual, Matcher (Object? ) matcherResolver) {
        
        if(is T actual) {
            
            variable Boolean succeeded = true;
            SequenceBuilder<ObjectFieldDescription> fieldDescrSb = SequenceBuilder<ObjectFieldDescription>(); 
            for(fieldMatcher in fieldMatchers) {
                
                Object? actualField = fieldMatcher.field(actual); 
                MatcherResult fieldResult = fieldMatcher.matcher(expected).match(actualField, matcherResolver);
                if(fieldResult.failed()) {
                    succeeded = false;
                }
                fieldDescrSb.append(ObjectFieldDescription(fieldMatcher.fieldName, fieldResult.matchDescription));
            }
            Description prefix = StringDescription(simpleClassName(expected), matchStyle(succeeded));
            ObjectDescription objectDescription = ObjectDescription (prefix, fieldDescrSb.sequence);
            
            return MatcherResult(succeeded, objectDescription);
            
        } else {    // actual is not a T
            return MatcherResult(false, wrongTypeDescription<T>(actual, expected, descriptor));
        }
    }
    
}

Description wrongTypeDescription<T>(
    Object? actual, 
    T expected, 
    Descriptor descriptor
) given T satisfies Object 
{
    variable String actualName = "<null>";
    if(exists actual) {
        actualName = className(actual);
    }
    Description d = CatDescription({
        StringDescription("A ``className(expected)`` was expected, found ``actualName``", highlighted),
        ValueDescription(highlighted, actual, descriptor)
    });
    
    return d;    
}

doc "Compound matcher, matches when all children matcher match."
by "Jean-Pierre Ragey"
shared class AllMatcher (
        doc "Children matchers"
        {Matcher *} matchers
        ) satisfies Matcher 
{
    doc "AllMatcher short description: \"All\""
    shared actual Description description(Matcher (Object? ) resolver) => StringDescription("All", normalStyle); 
    
    shared actual MatcherResult match(Object? actual, Matcher (Object? ) matcherResolver) {
        variable value failureCount = 0;
        SequenceBuilder<Description> descrSb = SequenceBuilder<Description>(); 
        for(matcher in matchers) {
            MatcherResult mr = matcher.match(actual, matcherResolver);
            if(mr.failed()) {
                failureCount++;
            }
            descrSb.append(ChildDescription(matcher.description(matcherResolver), mr.matchDescription));        
        }
        
        variable Description prefix;
        if(failureCount > 0) {
            prefix = StringDescription("AllMatcher: ``failureCount`` mismatch (``matchers.size`` matchers)");
        } else {
            prefix = description(matcherResolver);
        }
        
        CompoundDescription descr = CompoundDescription (prefix, descrSb.sequence/*, [], [], descriptor*/);
        MatcherResult result = MatcherResult(failureCount == 0, descr);
        return result;
    }
    
}

doc "Compound matcher, matches when any child matcher match."
by "Jean-Pierre Ragey"
shared class AnyMatcher (
        doc "Children matchers"
        {Matcher *} matchers
        ) satisfies Matcher 
{
    
    doc "AnyMatcher short description: \"Any\""
    shared actual Description description(Matcher (Object? ) resolver) => StringDescription("Any"); 
    
    shared actual MatcherResult match(Object? actual, Matcher (Object? ) matcherResolver) {

        variable value failureCount = 0;
        SequenceBuilder<Description> descrSb = SequenceBuilder<Description>(); 
        for(matcher in matchers) {
            MatcherResult mr = matcher.match(actual, matcherResolver);
            if(mr.failed()) {
                failureCount++;
            }
            descrSb.append(ChildDescription(matcher.description(matcherResolver), mr.matchDescription));        
        }
        
        Integer matchersSize = matchers.size; 
        Boolean succeeded = failureCount < matchersSize;
        variable Description? prefix = null;
        
        if(succeeded) {
            prefix = description(matcherResolver);
        } else {
            prefix = StringDescription("AnyMatcher: no matcher succeeded (``matchersSize`` matchers)");
        }
        
        CompoundDescription descr = CompoundDescription (prefix, descrSb.sequence/*, [], [], descriptor*/);
        MatcherResult result = MatcherResult(succeeded, descr);
        return result;
    }
    
}

doc "Matches when child fails, and vice-versa."
by "Jean-Pierre Ragey"
shared class NotMatcher (
        doc "Child matcher"
        Matcher matcher
        ) satisfies Matcher 
{
    
    doc "NotMatcher short description: \"Not\""
    shared actual Description description(Matcher (Object? ) resolver) => StringDescription("Not", normalStyle); 
    
    shared actual MatcherResult match(Object? actual, Matcher (Object? ) matcherResolver) {
   
        MatcherResult mr = matcher.match(actual, matcherResolver);
        ChildDescription childDescr = ChildDescription(matcher.description(matcherResolver), mr.matchDescription);        
        
        Boolean succeeded = ! mr.succeeded;
        variable Description? prefix = null;
        
        if(succeeded) {
            prefix = description(matcherResolver);
        } else {
            prefix = StringDescription("NotMatcher: child matcher succeeded");
        }
        
        CompoundDescription descr = CompoundDescription (prefix, [childDescr]/*, [], [], descriptor*/);
        MatcherResult result = MatcherResult(succeeded, descr);
        return result;
    }
    
}

doc "Always matches."
by "Jean-Pierre Ragey"
shared class AnythingMatcher (
        ) satisfies Matcher 
{
    
    doc "AnythingMatcher short description: \"Anything\""
    shared actual Description description(Matcher (Object? ) resolver) => StringDescription("Anything", normalStyle); 
    
    shared actual MatcherResult match(Object? actual, Matcher (Object? ) matcherResolver) {
        
        Description descr = StringDescription("Anything", normalStyle);
        MatcherResult result = MatcherResult(true, descr);
        return result;
    }
    
}

doc "Decorates a matcher result with a prefix, to improve readability."
by "Jean-Pierre Ragey"
shared class DescribedAsMatcher (
        doc "Prefix, to be prepended to child matcher match description"
        Description prefix,
        doc "Child matcher"
        Matcher matcher
        ) satisfies Matcher 
{
    doc "short description: \"DescribedAs\""
    shared actual Description description(Matcher (Object? ) resolver) => StringDescription("DescribedAs", normalStyle); 
    
    doc "Let the child matcher match `actual`; the result description is the concatenation
         of the prefix and the child match result description."
    shared actual MatcherResult match(Object? actual, Matcher (Object? ) matcherResolver) {
   
        MatcherResult mr = matcher.match(actual, matcherResolver);
        Description d = CatDescription({prefix, mr.matchDescription});
        MatcherResult result = MatcherResult(mr.succeeded, d);
        return result;
    }
    
}

doc "Match value type, according to `(is T actual)`.
         void typeMatcherExample() {
            assertThat(\"Hello\", TypeMatcher<String>());
         }
     NOTE: The error message doesn't print T type, since ceylon current version (0.5) has no way of finding T name.
     It may change when metaprogramming is supported. 
     "
by "Jean-Pierre Ragey"
shared class TypeMatcher<T> (
        doc "Descriptor to get actual value description, if matching fails. Defaults to [[DefaultDescriptor]]." 
        Descriptor descriptor = DefaultDescriptor()
        ) satisfies Matcher 
{
    doc "\"TypeMatcher\""
    shared actual Description description(Matcher (Object? ) resolver) => StringDescription("TypeMatcher", normalStyle); 
    
    shared actual MatcherResult match(Object? actual, Matcher (Object? ) matcherResolver) {

        MatcherResult result;

        if(is T actual) {
            result = MatcherResult(true, ValueDescription(normalStyle, actual, descriptor));
        } else {
            variable String actClassName ="<null>";
            if(exists actual) {
                actClassName = className(actual);
            }
            // TODO: find expected type (eg by metaprogramming) 
            Description fd = StringDescription("ERR: wrong type: found ``actClassName``: ", normalStyle);
            result = MatcherResult(false, CatDescription{
                fd, 
                ValueDescription(highlighted, actual, descriptor)
            });
        }
        return result;
    }
    
}

doc "Matches if actual value is an `Object` (ie if it's not null)"
by "Jean-Pierre Ragey"
shared class NotNullMatcher (
        doc "Descriptor for actual value."
        Descriptor descriptor = DefaultDescriptor()
        ) extends TypeMatcher<Object> (descriptor) {} 


doc "Matcher that delegates matching to an `expected` type dependent matcher, found by `resolver`.
     "
by "Jean-Pierre Ragey"
shared class Is(
        doc "Expected value"
        Object? expected
        ) satisfies Matcher {
    
    doc "Short description, based on the delegate matcher short description."
    shared actual Description description(Matcher (Object? ) resolver) => 
        CatDescription{
            StringDescription("Is: ", normalStyle), 
            resolver(expected).description(resolver)
        };
    
    doc "Delegate matching to [[matcher]]."
    shared actual MatcherResult match(Object? actual, Matcher (Object? ) resolver) {
        Matcher matcher = resolver(expected);
        return matcher.match(actual, resolver);
    }
}

