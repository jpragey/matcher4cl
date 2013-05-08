

doc "Convert a simple object to a String, used for description to string conversion."
see "`ValueDescription`"
by "Jean-Pierre Ragey"
shared interface Descriptor {
    shared formal String describe(Object? obj);
}

doc "Default descriptor:
     - null is written as \"&lt;null&gt;\";
     - Strings are enclosed in double-quotes;
     - otherwise the object `string` propert is returned.
     This may change in future (eg to improve readability). 
     "
by "Jean-Pierre Ragey"
shared class DefaultDescriptor() satisfies Descriptor {
    
    shared actual String describe(Object? obj) {
        
        if(is String obj) {
            return "\"" + obj.string + "\"";
        }
        
        return obj?.string else "<null>";
    }
}

