
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
        MatcherResolver matcherResolver = DefaultMatcherResolver());
    
    doc "Short one-line description, eg 'operator =='"
    shared formal Description description;
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
    shared actual Description description = ValueDescription(normalStyle, equalsDescriptionString);
    
    doc "Perform the match:
         - succeeds if both actual/expected values are null;
         - fails if only one is null;
         - fails if `actual` is not a T or a subtype of T;
         - if both are non-null, delegate matching to the `equals` constructor parameter. 
         "
    shared actual MatcherResult match(Object? actual,
        
        MatcherResolver matcherResolver) {
        Boolean matched ;
        Description d;
        
        if(exists expected) {
            
            if(is T actual) {
                Description? failDescription = equals(expected, actual);
                matched = failDescription is Null;
                d = MatchDescription(failDescription, matchStyle(matched), expected, actual, descriptor);
                
            } else if(exists actual){
                matched = false;
                Description fd = StringDescription( normalStyle, "ERR: ``className(expected)`` was expected, found ``className(actual)``: ");
                d = MatchDescription(fd, highlighted, expected, actual, descriptor);
            } else {
                matched = false;
                FormattedDescription fd = FormattedDescription(DefaultFormatter("ERR: non-null was expected: "), []);
                d = MatchDescription(fd, highlighted, expected, actual, descriptor);
            }
            
        } else {
            matched = actual is Null;
            
            if(matched) {
                d = MatchDescription(null, normalStyle, expected, actual, descriptor);
            } else {
                FormattedDescription fd = FormattedDescription(DefaultFormatter("ERR: <null> was expected: "), []);
                d = MatchDescription(fd, matchStyle(matched), expected, actual, descriptor);
            }
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
            else {return StringDescription(normalStyle, "'=='");}
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
            else {return StringDescription(highlighted, "'==='");}
        },
        "===", 
        descriptor)
{}

by "Jean-Pierre Ragey"
object matcherFormatters {
    doc "Position in list prefix"
    shared Formatter listPositionFmt = DefaultFormatter("At position {} ");   

    shared Formatter mapValueMismatchFmt = DefaultFormatter("Value mismatch for ");   
    shared Formatter allMatchersFailurePrefix = DefaultFormatter("AllMatcher: {} mismatch ({} matchers)");   
    shared Formatter anyMatchersFailurePrefix = DefaultFormatter("AnyMatcher: no matcher succeeded ({} matchers)");   
    shared Formatter notMatcherFailurePrefix = DefaultFormatter("NotMatcher: child matcher succeeded");   
    
}

doc "Matcher for `Iterable` values."
by "Jean-Pierre Ragey"
shared class ListMatcher(
        doc "Expected elements"
        {Object *} expected,
        doc "Descriptor for elements decriptions " 
        Descriptor descriptor = DefaultDescriptor()
        ) satisfies Matcher 
{
    doc "\"ListMatcher\""
    shared actual Description description = ValueDescription(normalStyle, "ListMatcher");
    
    doc "Actual and expected list elements are matched one by one; matchers are found by `matcherResolver`.
         It fails if `actual` is not an `Iterable`, if list lengths differ, or if any element match fails.
         "
    shared actual MatcherResult match(Object? actual,
        
        MatcherResolver matcherResolver) {
        MatcherResult result;
        
        if(is Iterable<Object> actual) {
            
            SequenceBuilder<Description> elementsDescrSb = SequenceBuilder<Description>();
            SequenceBuilder<Description> extraActualDescrSb = SequenceBuilder<Description>();
            SequenceBuilder<Description> extraExpectedDescrSb = SequenceBuilder<Description>();
            variable Integer mismatchCount = 0;
            
            Iterator<Object> expIt = expected.iterator();
            Iterator<Object> actIt = actual.iterator();
            variable Integer index = 0;
            while(!is Finished a = actIt.next()) {
                if(!is Finished e = expIt.next()) {
                    // -- Compare elements
                    Matcher elemMatcher = matcherResolver.findMatcher(e);
                    MatcherResult mr = elemMatcher.match(a, matcherResolver);
                    
                    Boolean matched = mr.succeeded;
                    variable Description md = mr.matchDescription;
                    
                    if(!matched) {  // Append element index
                        md = CatDescription{
                            FormattedDescription(matcherFormatters.listPositionFmt, [index], highlighted /*error*/),
                            elemMatcher.description,
                            StringDescription(normalStyle, ": "),
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
                failureDescription = FormattedDescription(DefaultFormatter("{} mismatched:"), [mismatchCount]);
            } else if(! extraActualDescrSb.empty) {
                failureDescription = FormattedDescription(DefaultFormatter("Actual list is longer than expected: {} expected, {} actual: "), [expected.size, actual.size]);
            } else if(! extraExpectedDescrSb.empty) {
                failureDescription = FormattedDescription(DefaultFormatter("Expected list is longer than actual: {} expected, {} actual: "), [expected.size, actual.size]);
            } else {
                failureDescription = null;
                succeded = true;
            }
            
            ListDescription ld = ListDescription(failureDescription, elementsDescrSb.sequence, extraExpectedDescrSb.sequence, extraActualDescrSb.sequence);
            result = MatcherResult(succeded, ld);
            
        } else if(exists actual){
            result = MatcherResult(false, StringDescription(highlighted, "An iterator was expected, found ``className(actual)``"));
        } else {
            result = MatcherResult(false, StringDescription(highlighted, "An iterator was expected, found null"));
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
    shared actual Description description = ValueDescription(normalStyle, "MapMatcher");
    
    shared actual MatcherResult match(Object? actual, MatcherResolver matcherResolver) {
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
                Matcher itemMatcher = matcherResolver.findMatcher(expectedItem);
                
                MatcherResult mr = itemMatcher.match(actualItem, matcherResolver);
                
                Boolean matched = mr.succeeded;
                variable Description? prefix = null;
                
                if(!matched) {
                    prefix = CatDescription{
                        FormattedDescription(matcherFormatters.mapValueMismatchFmt, [], normalStyle),
                                itemMatcher.description,
                                StringDescription(highlighted, ": ")
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
                failureDescription = FormattedDescription(DefaultFormatter("{} values mismatched:"), [mismatchCount]);
            } else if(! extraActual.empty) {
                failureDescription = FormattedDescription(DefaultFormatter("Actual map is longer than expected: {} expected, {} actual: "), [expected.size, actual.size]);
            } else if(! extraExpected.empty) {
                failureDescription = FormattedDescription(DefaultFormatter("Expected map is longer than actual: {} expected, {} actual: "), [expected.size, actual.size]);
            } else {
                failureDescription = null;
                succeded = true;
            }
            
            MapDescription ld = MapDescription(failureDescription, elementsDescrSb.sequence, extraExpected.sequence, extraActual.sequence/*, descriptor*/);
            result = MatcherResult(succeded, ld);
            
        } else if(exists actual){
            result = MatcherResult(false, StringDescription(highlighted, "A Map was expected, found ``className(actual)``"));
        } else {
            result = MatcherResult(false, StringDescription(highlighted, "A Map was expected, found null"));
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
    shared actual Description description = StringDescription(normalStyle/*error*/, "ObjectMatcher"); 
    
    String simpleClassName(Object obj) {
        String cn = className(obj); 
        return cn.split(":", true, true).last else cn;
    }
    
    shared actual MatcherResult match(Object? actual, MatcherResolver matcherResolver) {
        
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
            Description prefix = StringDescription(matchStyle(succeeded), simpleClassName(expected));
            ObjectDescription objectDescription = ObjectDescription (prefix, fieldDescrSb.sequence/*, descriptor*/);
            
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
        StringDescription(highlighted, "A ``className(expected)`` was expected, found ``actualName``"),
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
    shared actual Description description = StringDescription(normalStyle/*error*/, "All"); 
    
    shared actual MatcherResult match(Object? actual, MatcherResolver matcherResolver) {

        variable value failureCount = 0;
        SequenceBuilder<Description> descrSb = SequenceBuilder<Description>(); 
        for(matcher in matchers) {
            MatcherResult mr = matcher.match(actual, matcherResolver);
            if(mr.failed()) {
                failureCount++;
            }
            descrSb.append(ChildDescription(matcher.description, mr.matchDescription));        
        }
        
        variable Description prefix;
        if(failureCount > 0) {
            prefix = FormattedDescription(matcherFormatters.allMatchersFailurePrefix, [failureCount, matchers.size]);
        } else {
            prefix = description;
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
    shared actual Description description = StringDescription(normalStyle, "Any"); 
    
    shared actual MatcherResult match(Object? actual, MatcherResolver matcherResolver) {

        variable value failureCount = 0;
        SequenceBuilder<Description> descrSb = SequenceBuilder<Description>(); 
        for(matcher in matchers) {
            MatcherResult mr = matcher.match(actual, matcherResolver);
            if(mr.failed()) {
                failureCount++;
            }
            descrSb.append(ChildDescription(matcher.description, mr.matchDescription));        
        }
        
        Integer matchersSize = matchers.size; 
        Boolean succeeded = failureCount < matchersSize;
        variable Description? prefix = null;
        
        if(succeeded) {
            prefix = description;
        } else {
            prefix = FormattedDescription(matcherFormatters.anyMatchersFailurePrefix, [matchersSize]);
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
    shared actual Description description = StringDescription(normalStyle/*error*/, "Not"); 
    
    shared actual MatcherResult match(Object? actual, MatcherResolver matcherResolver) {
   
        MatcherResult mr = matcher.match(actual, matcherResolver);
        ChildDescription childDescr = ChildDescription(matcher.description, mr.matchDescription);        
        
        Boolean succeeded = ! mr.succeeded;
        variable Description? prefix = null;
        
        if(succeeded) {
            prefix = description;
        } else {
            prefix = FormattedDescription(matcherFormatters.notMatcherFailurePrefix, []);
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
    shared actual Description description = StringDescription(normalStyle, "Anything"); 
    
    shared actual MatcherResult match(Object? actual, MatcherResolver matcherResolver) {
        
        Description descr = StringDescription(normalStyle, "Anything");
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
    shared actual Description description = StringDescription(normalStyle, "DescribedAs"); 
    
    doc "Let the child matcher match `actual`; the result description is the concatenation
         of the prefix and the child match result description."
    shared actual MatcherResult match(Object? actual, MatcherResolver matcherResolver) {
   
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
    shared actual Description description = StringDescription(normalStyle/*error*/, "TypeMatcher"); 
    
    shared actual MatcherResult match(Object? actual, MatcherResolver matcherResolver) {

        MatcherResult result;

        if(is T actual) {
            result = MatcherResult(true, ValueDescription(normalStyle, actual, descriptor));
        } else {
            variable String actClassName ="<null>";
            if(exists actual) {
                actClassName = className(actual);
            }
            // TODO: find expected type (eg by metaprogramming) 
//            FormattedDescription fd = FormattedDescription(DefaultFormatter("ERR: wrong type: found {}: "), [actClassName]);
            Description fd = StringDescription(normalStyle, "ERR: wrong type: found ``actClassName``: ");
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
        Object? expected,
        doc "Resolver, used to get a matcher for `expected` value"
        MatcherResolver resolver = DefaultMatcherResolver()
        ) satisfies Matcher {
    
    doc "The delegate matcher, given by `resolver` for the expected type value."
    shared Matcher matcher = resolver.findMatcher(expected);
    
    doc "Short description, based on the delegate matcher short description."
    shared actual Description description = CatDescription{StringDescription(normalStyle, "Is: "), matcher.description};
    
    doc "Delegate matching to [[matcher]]."
    shared actual MatcherResult match(Object? actual, MatcherResolver matcherResolver) {
        return matcher.match(actual, matcherResolver);
    }
}

