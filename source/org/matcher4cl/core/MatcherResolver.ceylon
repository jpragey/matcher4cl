
doc "Find a 'suitable' matcher for a given expected object."
by "Jean-Pierre Ragey"
shared interface MatcherResolver {
    doc "Find a 'suitable' matcher for a given expected object."
    shared formal Matcher findMatcher(Object? expected);
}

doc "Find a 'suitable' matcher for a given expected object, if any.
     It is typically used to with [[DefaultMatcherResolver]] to create custom matcher resolver:
     `OptionalMatcherResolver` will check for custom objects matchers, 
     and falls back to [[DefaultMatcherResolver]] for other objects. 
     "
see "DefaultMatcherResolver"     
by "Jean-Pierre Ragey"
shared interface OptionalMatcherResolver {
    doc "Find a 'suitable' matcher for a given expected object.
         Returns null if not found."
    shared formal Matcher? findMatcher(Object? expected);
}



doc "Default `MatcherResolver`, use delegates (usually for custom matchers) and, if not found, a few default matchers."
by "Jean-Pierre Ragey"
shared class DefaultMatcherResolver(
    doc "Delegates, will be asked first, in this order."
    {OptionalMatcherResolver *} delegates = {},
    doc "The descriptor that will be passed to created Matchers."
    Descriptor descriptor = DefaultDescriptor()
    ) satisfies MatcherResolver 
{
    
    doc "It first asks the delegates for a matcher; if they all return null, it tries the following mapping:
         - `String`: returns an [[EqualsMatcher]];
         - `Map<Object, Object>`: returns an [[MapMatcher]]`;
         - non-empty collection of `Entry<Object, Object>`: returns a [[MapMatcher]]; expected is converted to `LazyMap` (may be changed later).
           It allows simple in-line maps (for example, `findMatcher({\"A\"->\"AA\", \"B\"->\"BB\"})`;
         - `Iterable<Object>`: returns an [[ListMatcher]];
         - other objects and `null`s: returns an [[EqualsMatcher]].
         " 
    shared actual Matcher findMatcher(Object? expected) {

        for(d in delegates) {
            if(exists m = d.findMatcher(expected)) {
                return m; 
            }
        }

        // -- String (BEFORE collections, as String are lists of characters...)         
        if(is String expected) {
            return EqualsMatcher(expected, descriptor);
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
}

