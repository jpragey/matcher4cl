
"Get a Matcher for an expected object.
 It first queries delegates; if they all return null, it tries the following mapping:
 - `String`: returns an [[StringMatcher]];
 - non-empty collection of `Entry<Object, Object>`: returns a [[MapMatcher]]; expected is converted to `LazyMap` (may be changed later).
   It allows simple in-line maps (for example, `findMatcher({\"A\"->\"AA\", \"B\"->\"BB\"})`;
 - `Map<Object, Object>`: returns an [[MapMatcher]]`;
 - `Iterable<Object>`: returns an [[ListMatcher]];
 - other objects and `null`s: returns an [[EqualsMatcher]].
 " 
shared Matcher defaultResolver(

    "Delegate resolvers, will be asked first, in this order.
     If any of then returns a Matcher, this matcher will be used."
    Matcher? (Object? )? delegate = null,
    
    "The descriptor that will be passed to created Matchers."
    Descriptor descriptor = DefaultDescriptor()
    )
    (
    "expected object"
    Object? expected) 
{

    if(exists delegate, exists m = delegate(expected)) {
        return m; 
    }

    // -- String (BEFORE collections, as String are lists of characters...)         
    if(is String expected) {
        return StringMatcher{expected=expected; descriptor=descriptor;};
    }
    
    // -- Collections of entries: MapMatcher
    if(is Collection<Object -> Object> expected, !expected.empty) {
        return MapMatcher(LazyMap(expected), descriptor);
    }
    
    if(is Map<Object, Object> expected) {
        return MapMatcher(expected, descriptor);
    }
    
    // -- Other iterables
    if(is Iterable<Object?> expected) {
        return ListMatcher(expected, descriptor);
    }
    
    // -- Nulls and other objects
    return EqualsMatcher(expected, descriptor);
    
}

