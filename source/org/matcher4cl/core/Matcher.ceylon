import java.lang { arrays, JString = String, JLong = Long, NoSuchFieldException, SecurityException, IllegalArgumentException, IllegalAccessException, NoSuchMethodException, Class, RuntimeException }
import ceylon.collection { HashSet }
import java.util { JIterator = Iterator }
import java.lang.reflect { InvocationTargetException }
import ceylon.language.metamodel { type, Attribute }
import ceylon.language.metamodel.declaration { ClassDeclaration, AttributeDeclaration }


"Result of a [[Matcher]] match."
by ("Jean-Pierre Ragey")
shared class MatcherResult(succeeded, matchDescription) {
    "true if match succeeded, false otherwise."
    shared Boolean succeeded;
    
    "Description of matched objects. It is typically a tree of [[Description]]s, where [[MatchDescription]] 
         mark simple values comparisons, and decorated by mismatch indications.
         Note that it must be present even if matching succeeded, as [[NotMatcher]] uses successful match descriptions
         as mismatch description."
    shared Description matchDescription;
    
    "Convenient method that returns the opposite of `succeeded`."
    shared Boolean failed() {
        return !succeeded;
    }
}

"Matches an actual value against some criterion (usually an 'expected' value passed to constructor)"
by ("Jean-Pierre Ragey")
shared interface Matcher {
    "Performs the match."
    shared formal MatcherResult match(
        "The value to match."
        Object? actual,
        "Resolver: implementations may use it to get matcher for members. 
             Useful for somewhat generic class matchers, eg matchers for lists or maps."
        Matcher (Object? ) resolver = defaultMatcherResolver());
    
    "Short one-line description, eg 'operator =='"
    shared formal Description description(Matcher (Object? ) resolver);
}

"Matcher based on comparison between two simple values, like Integer or String. 
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
by ("Jean-Pierre Ragey")
shared abstract class EqualsOpMatcher<T>(
    "The expected value"
    T? expected, 
    "Value comparator: returns null if first arg (expected) matches  the second arg (actual),
         otherwise return a mismatch description." 
    Description?(T, T) equals,
    "A short description of the matcher (eg '=='). Suggestion: add matcher parameters, eg error margin."
    String equalsDescriptionString, 
    "Descriptor for actual/expected values formatting"
    Descriptor descriptor = DefaultDescriptor()
    
    ) satisfies Matcher 
    given T satisfies Object
{
    
    "Same content as constructor `equalsDescriptionString` parameter."
    shared actual Description description(Matcher (Object? ) resolver) => ValueDescription(normalStyle, equalsDescriptionString);
    
    "Perform the match:
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

"Matcher for String"
by ("Jean-Pierre Ragey")
shared class StringMatcher(
    "The expected value"
    String expected,
    
    "Converts actual and expected values before processing. For example, if you use `(String s) => s.uppercased`, 
         matching will be case insensitive."
    String(String) convert = (String s) => s,
       
    "Descriptor for actual values formatting"
    Descriptor descriptor = DefaultDescriptor()
    ) satisfies Matcher 
{
    
    "Same content as constructor `equalsDescriptionString` parameter."
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
        StringBuilder sb = StringBuilder();
        appendHexChars(c.integer, sb);
        String s = sb.string;
        return s;
    }
    
    "Perform the match:
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
            String expString = convert(expected); 
            String actString = convert(actual); 
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
                                    ": expected[``index``]=\'``e``\'(``e.integer``=#``toHex(e)``) != actual[``index``]=\'``a``\'(``a.integer``=#``toHex(a)``)");
                                break; 
                            }
                        }
                        index++;
                    }
                }
                
                if(exists fd = failDescription) {
                    d = CatDescription({MatchDescription(null, highlighted, expected, actual, descriptor), fd});
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


"Matcher based on '==' comparison"
by ("Jean-Pierre Ragey")
shared class EqualsMatcher(
    "Expected value"
    Object? expected, 
    "Descriptor, used to print expected/actual values if they are not equal."
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

"Matcher based on '===' comparison"
by ("Jean-Pierre Ragey")
shared class IdentifiableMatcher(
    "Expected value"
    Identifiable expected, 
    "Descriptor, used to print expected/actual values if they don't refer to the same instance."
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


"Matcher for `Iterable` values."
by ("Jean-Pierre Ragey")
shared class ListMatcher(
        "Expected elements"
        {Object? *} expected,
        "Descriptor for elements decriptions " 
        Descriptor descriptor = DefaultDescriptor()
        ) satisfies Matcher 
{
    "\"ListMatcher\""
    shared actual Description description(Matcher (Object? ) resolver) => ValueDescription(normalStyle, "ListMatcher");
    
    "Actual and expected list elements are matched one by one; matchers are found by `matcherResolver`.
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

"Matcher for `Map`s.
     Maps match if:
     - they have the same set of keys;
     - for each key, actual and expected values match.  
     "
by ("Jean-Pierre Ragey")
shared class MapMatcher<Key, Item>(
        "Expected map"
        Map<Key, Item> expected,
        //"Resolver for values matching" 
        //MatcherResolver matcherResolver = DefaultMatcherResolver(),
        "Descriptor for both keys and simple values." 
        Descriptor descriptor = DefaultDescriptor()
        
        ) satisfies Matcher 
        given Key satisfies Object
        given Item satisfies Object
{
    
    "\"MapMatcher\""
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

"Adapter for a custom class T field, to by used with [[ObjectMatcher]].
 The field of actual value is returned by `field()`.
 "
see ("ObjectMatcher")     
by ("Jean-Pierre Ragey")
shared class FieldAdapter<T>(
    "Class field name, for description"
    shared String fieldName,
    "Matcher for the expected field"
    shared Matcher matcher,
    "Return the value of the field of `actual`"
    shared Object? (T) field
    ) 
    given T satisfies Object
{
    shared MatcherResult match(T actual, Matcher (Object? ) matcherResolver) {
        try {
            Object? actualField = field(actual);
            return matcher.match(actualField, matcherResolver);
            
        } catch (NoSuchFieldException | SecurityException | IllegalArgumentException | IllegalAccessException 
                 | NoSuchMethodException | InvocationTargetException e) {
            value descr = StringDescription("an ``className(e)`` occured while accessing field ``fieldName`` of ``className(actual)`` : ``e.message``", highlighted);
            return MatcherResult(false, descr);
        }
        
    }
}


"Behaviour of [[ObjectMatcher]] when its field adapter list doesn't cover all expected object list.
 Concrete implementations may return an error, or create suitable adapters (possibly none).
 "
shared abstract class MissingAdapterStrategy<T>() given T satisfies Object {
    // We can't create missing FieldAdapters directly because they require a resolver, available in match() only;
    // so we create builders for them.
    shared alias AdapterBuilder => FieldAdapter<T> (Matcher /*resolver*/(Object? ) );

    shared formal Description | {AdapterBuilder *} createAdapterBuilders(T expected, {FieldAdapter<T> *} fieldAdapters);

    ""
    shared default Description | Iterable<FieldAdapter<T>> appendMissingAdapters(T expected, {FieldAdapter<T> *} fieldAdapters, Matcher (Object? ) matcherResolver) {
        Description | {AdapterBuilder *} adapterBuilders =  createAdapterBuilders(expected, fieldAdapters);
        if(is Description adapterBuilders) {
            return adapterBuilders;
        }
        assert(is {AdapterBuilder *} adapterBuilders);
        
        {FieldAdapter<T> *} missingAdapters = adapterBuilders.map((FieldAdapter<T>(Matcher(Object?)) elem) => elem(matcherResolver)); 
        
        // NOTE :  the following lines could be replaced by :
        //        {FieldAdapter<T> *} currentFieldAdapters = fieldAdapters.chain(missingAdapters);
        // but chain() return value clashes with type() (Ceylon bug)
        SequenceBuilder<FieldAdapter<T>> fab = SequenceBuilder<FieldAdapter<T>>();
        fab.appendAll(fieldAdapters); 
        fab.appendAll(missingAdapters); 
        {FieldAdapter<T> *} currentFieldAdapters = fab.sequence;
        
        return currentFieldAdapters;
    }
}

"[[MissingAdapterStrategy]] that fails if any field adapter is missing: field adapters are mandatory for ALL fields.
 
 Note that it works only for shared top-level classes and non-shared nested classes (due to current Ceylon metaprogramming limitations). 
 "
see ("ObjectMatcher") 
shared class FailForMissingAdapter<T>() extends MissingAdapterStrategy<T>() given T satisfies Object {
    shared actual Description | {AdapterBuilder *} createAdapterBuilders(T expected, {FieldAdapter<T> *} fieldAdapters) {
        HashSet<String> adaptersFieldNames = HashSet<String>(fieldAdapters.map((FieldAdapter<T> fa) => fa.fieldName));

        value t = type(expected);
        ClassDeclaration classDeclaration;
        try {
            classDeclaration = t.declaration;
        } catch (RuntimeException e) {
            return TreeDescription(StringDescription(e.message), [ 
                StringDescription("A RuntimeException occured while getting expected type declaration. "),
                StringDescription("Note that ObjectMatcher with FailForMissingAdapter strategy only supports top-level shared classes (Ceylon current limitation)."),
                StringDescription("In this case, consider using IgnoreMissingAdapters and defining adapters for all fields.")
            ]);
        }
    
        AttributeDeclaration[] attrs = classDeclaration.members<AttributeDeclaration>();
        Set<String> objectFieldNames = HashSet(attrs.map((AttributeDeclaration decl) => decl.name));
        
        Set<String> missingFieldNames = objectFieldNames.complement(adaptersFieldNames);
        if(!missingFieldNames.empty) {
            String msg = "Class field(s) without FieldAdapter: `` ", ".join(missingFieldNames) ``";
            return StringDescription(msg);
        }
        return {};
    }    
}
"[[MissingAdapterStrategy]] that doesn't care about missing field adapters: field adapters are always optional.
 "
see ("ObjectMatcher") 
shared class IgnoreMissingAdapters<T>() extends MissingAdapterStrategy<T>() given T satisfies Object {
    shared actual Description | {AdapterBuilder *} createAdapterBuilders(T expected, {FieldAdapter<T> *} fieldAdapters) {
        return {};
    }    
}
"[[MissingAdapterStrategy]] that creates adapters for missing fields, using metamodel.
 Field names come from the metamodel, and field matchers are created by the ObjectMatcher.match() resolver argument.
 
 Note that it works only for shared top-level classes (due to current Ceylon metaprogramming limitations). 
 "
see ("ObjectMatcher") 
shared class CreateMissingAdapters<T>() extends MissingAdapterStrategy<T>() given T satisfies Object {
    shared actual Description | {AdapterBuilder *} createAdapterBuilders(T expected, {FieldAdapter<T> *} fieldAdapters) {
        
        value t = type(expected);
        ClassDeclaration classDeclaration;
        try {
            classDeclaration = t.declaration;
        } catch (RuntimeException e) {
            return TreeDescription(StringDescription(e.message), [ 
                StringDescription("A RuntimeException occured while getting expected type declaration. "),
                StringDescription("Note that ObjectMatcher with CreateMissingAdapters strategy only supports top-level shared classes (Ceylon current limitation)."),
                StringDescription("In this case, consider using IgnoreMissingAdapters and defining adapters for all fields.")
            ]);
        }
        
        AttributeDeclaration[] attrs = classDeclaration.members<AttributeDeclaration>();
        Set<String> objectFieldNames = HashSet(attrs.map((AttributeDeclaration decl) => decl.name));
        
        HashSet<String> adaptersFieldNames = HashSet<String>(fieldAdapters.map((FieldAdapter<T> fa) => fa.fieldName));
        
        SequenceBuilder<Description> errBuilder = SequenceBuilder<Description>();
        
        Set<String> checkedButUndefined = adaptersFieldNames.complement(objectFieldNames);
        if(!checkedButUndefined.empty) {
            String msg = "FieldAdapter(s) without class fields: `` ", ".join(checkedButUndefined) ``";
            errBuilder.append(StringDescription(msg));
        }
        
        SequenceBuilder<AdapterBuilder> missingAdaptersBuilder = SequenceBuilder<AdapterBuilder>();

        Set<String> definedButNotChecked = objectFieldNames.complement(adaptersFieldNames);
        if(!definedButNotChecked.empty) {
            
            for(fieldName in definedButNotChecked) {
                // 
                AttributeDeclaration? attrDecl = classDeclaration.getMember<AttributeDeclaration>(fieldName);
                assert (exists attrDecl);
                Object? extractor(Object act)  {
                    Attribute<Anything> attr = attrDecl.apply(act); 
                    return attr.get() else null;
                }
                Object? expectedField;
                try {
                    expectedField = attrDecl.apply(expected).get() else null;
                } catch (RuntimeException e) {
                    return TreeDescription(StringDescription(e.message), [ 
                        StringDescription("A RuntimeException occured while getting field ``fieldName`` of expected object of type ``classDeclaration.name``. "),
                        StringDescription("Note that ObjectMatcher with CreateMissingAdapters strategy only supports top-level shared classes (Ceylon current limitation)."),
                        StringDescription("In this case, consider using IgnoreMissingAdapters and defining adapters for all fields.")
                    ]);
                    
                }
                AdapterBuilder ab = (Matcher (Object? ) resolver)  => FieldAdapter<T>(fieldName,resolver(expectedField),  extractor);
                missingAdaptersBuilder.append(ab);
            }
        }
        
        if(errBuilder.empty) {
            return missingAdaptersBuilder.sequence;
        } else {
            return TreeDescription(StringDescription("ObjectMatcher<``className(expected)``>: FieldAdapter list and class fields don't match."), 
                        errBuilder.sequence);
        }
    }
}

"Custom class matcher.
 It checks if actual value is a T (or a subtype of),
 then use a list of [[FieldAdapter]] to get matchers for its fields and the fields themselves;
 match succeeds if all field matchers succeed.
 
 The `fieldAdapters` list may not exaclty match the tested class field; [[missingAdapterStrategy]] 
 handles these differences:
 - by default, [[CreateMissingAdapters]] is used; it reports adapters with names of non-existing fields,
   and tries to create missing adapters, based on metaprogramming and using the matcher resolver to create the field matchers;
 - [[FailForMissingAdapter]] (fails if any field has no adapter) and [[IgnoreMissingAdapters]] (doesn't care about missing adapters) 
   can also be used. 
 
 NOTE: due to limitations in current Ceylon metaprogramming feature, non-shared or nested classes may lead to RuntimeExceptions 
 in Ceylon runtime. In this case, you could typically use [[IgnoreMissingAdapters]] (but you loose fields checking - beware to update 
 field adapters when you add or remove a field to a custom class)
 Currently working combinations are (roughly):
 
 <table class = \"table table-bordered\">
   <tr><td>                      </td><td> shared TopLevel </td><td> non-shared TopLevel </td><td> shared Nested </td><td> non-shared Nested </td></tr>
   <tr><td>FailForMissingAdapter </td><td>        OK       </td><td>       -             </td><td>      -        </td><td>       OK          </td></tr>
   <tr><td>IgnoreMissingAdapters </td><td>        OK       </td><td>       OK            </td><td>      OK       </td><td>       OK          </td></tr>
   <tr><td>CreateMissingAdapters </td><td>        OK       </td><td>       -             </td><td>      -        </td><td>       -           </td></tr>
 </table>
 
 If you want to explicitely ignore some field, use [[AnythingMatcher]].   
 "
by ("Jean-Pierre Ragey")
shared class ObjectMatcher<T> (
        "The expected object."
        T expected,
        "Adapters for each field, to get actual objects fields and field matchers."
        {FieldAdapter<T> *} fieldAdapters = {},
        "Descriptor used to describe actual value, if its type doesn't describe the expected one."
        Descriptor descriptor = DefaultDescriptor(),
        
        "Handling of missing field adapters"
         MissingAdapterStrategy<T> missingAdapterStrategy = CreateMissingAdapters<T>()
        ) satisfies Matcher 
        given T satisfies Object
{
    "\"ObjectMatcher\" (subject to change, may include T name in future)"
    shared actual Description description(Matcher (Object? ) resolver) => StringDescription("ObjectMatcher", normalStyle); 
    
    String simpleClassName(Object obj) {
        String cn = className(obj); 
        return cn.split(":", true, true).last else cn;
    }
    
    
    shared actual MatcherResult match(Object? actual, Matcher (Object? ) matcherResolver) {
        
        Description | Iterable<FieldAdapter<T>> currentFieldAdapters = missingAdapterStrategy.appendMissingAdapters(expected, fieldAdapters, matcherResolver);
        if(is Description currentFieldAdapters) {
            return MatcherResult(false, currentFieldAdapters);
        }
 //       doc("currentFieldAdapters: {FieldAdapter<T> *} expected, found ``currentFieldAdapters then className(currentFieldAdapters) else ""``" +className(currentFieldAdapters))
        assert(is Iterable<FieldAdapter<T>> currentFieldAdapters);
        
        if(is T actual) {
            
            variable Boolean succeeded = true;
            SequenceBuilder<ObjectFieldDescription> fieldDescrSb = SequenceBuilder<ObjectFieldDescription>();
            
            for(fieldMatcher in currentFieldAdapters) {
                
                MatcherResult fieldResult = fieldMatcher.match(actual, matcherResolver);
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

"Compound matcher, matches when all children matcher match."
by ("Jean-Pierre Ragey")
shared class AllMatcher (
        "Children matchers"
        {Matcher *} matchers
        ) satisfies Matcher 
{
    "AllMatcher short description: \"All\""
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

"Compound matcher, matches when any child matcher match."
by ("Jean-Pierre Ragey")
shared class AnyMatcher (
        "Children matchers"
        {Matcher *} matchers
        ) satisfies Matcher 
{
    
    "AnyMatcher short description: \"Any\""
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

"Matches when child fails, and vice-versa."
by ("Jean-Pierre Ragey")
shared class NotMatcher (
        "Child matcher"
        Matcher matcher
        ) satisfies Matcher 
{
    
    "NotMatcher short description: \"Not\""
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

"Always matches."
by ("Jean-Pierre Ragey")
shared class AnythingMatcher (
        ) satisfies Matcher 
{
    
    "AnythingMatcher short description: \"Anything\""
    shared actual Description description(Matcher (Object? ) resolver) => StringDescription("Anything", normalStyle); 
    
    shared actual MatcherResult match(Object? actual, Matcher (Object? ) matcherResolver) {
        
        Description descr = StringDescription("Anything", normalStyle);
        MatcherResult result = MatcherResult(true, descr);
        return result;
    }
    
}

"Decorates a matcher result with a prefix, to improve readability."
by ("Jean-Pierre Ragey")
shared class DescribedAsMatcher (
        "Prefix, to be prepended to child matcher match description"
        Description prefix,
        "Child matcher"
        Matcher matcher
        ) satisfies Matcher 
{
    "short description: \"DescribedAs\""
    shared actual Description description(Matcher (Object? ) resolver) => StringDescription("DescribedAs", normalStyle); 
    
    "Let the child matcher match `actual`; the result description is the concatenation
         of the prefix and the child match result description."
    shared actual MatcherResult match(Object? actual, Matcher (Object? ) matcherResolver) {
   
        MatcherResult mr = matcher.match(actual, matcherResolver);
        Description d = CatDescription({prefix, mr.matchDescription});
        MatcherResult result = MatcherResult(mr.succeeded, d);
        return result;
    }
    
}

"Match value type, according to `(is T actual)`.
         void typeMatcherExample() {
            assertThat(\"Hello\", TypeMatcher<String>());
         }
     NOTE: The error message doesn't print T type, since ceylon current version (0.5) has no way of finding T name.
     It may change when metaprogramming is supported. 
     "
by ("Jean-Pierre Ragey")
shared class TypeMatcher<T> (
        "Descriptor to get actual value description, if matching fails. Defaults to [[DefaultDescriptor]]." 
        Descriptor descriptor = DefaultDescriptor()
        ) satisfies Matcher 
{
    "\"TypeMatcher\""
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

"Matches if actual value is an `Object` (ie if it's not null)"
by ("Jean-Pierre Ragey")
shared class NotNullMatcher (
        "Descriptor for actual value."
        Descriptor descriptor = DefaultDescriptor()
        ) extends TypeMatcher<Object> (descriptor) {} 


"Matcher that delegates matching to an `expected` type dependent matcher, found by `resolver`.
     "
by ("Jean-Pierre Ragey")
shared class Is(
        "Expected value"
        Object? expected
        ) satisfies Matcher {
    
    "Short description, based on the delegate matcher short description."
    shared actual Description description(Matcher (Object? ) resolver) => 
        CatDescription{
            StringDescription("Is: ", normalStyle), 
            resolver(expected).description(resolver)
        };
    
    "Delegate matching to [[matcher]]."
    shared actual MatcherResult match(Object? actual, Matcher (Object? ) resolver) {
        Matcher matcher = resolver(expected);
        return matcher.match(actual, resolver);
    }
}

