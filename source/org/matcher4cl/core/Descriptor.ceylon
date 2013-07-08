
"Descriptor environment"
shared interface DescriptorEnv {
    "Create a new FootNote"
    shared formal FootNote newFootNote(Description description);
 
}

"Default descriptor environment.
 It collects the `FootNote`s created by [[newFootNote]]; they are made available by [[footNotes]]  
 "
shared class DefaultDescriptorEnv() satisfies DescriptorEnv {
    
    variable Integer refCount = 0;
    SequenceBuilder<FootNote> footNotesBuilder = SequenceBuilder<FootNote>();
    
    shared actual FootNote newFootNote(Description description) {
         FootNote footNote = FootNote(refCount++, description);
         footNotesBuilder.append(footNote);
         return footNote;
    }
    "Get current footnote list."
    shared {FootNote*} footNotes() {
        return footNotesBuilder.sequence;
    }
}

"Convert a simple object to a String, used for description to string conversion."
see ("`ValueDescription`")
by ("Jean-Pierre Ragey")
shared interface Descriptor {
    "Return a (short) decsription of `obj`. "
    shared formal String describe(
        "The object to describe"
        Object? obj,
        "Utilities for description (eg to create footnotes)" 
        DescriptorEnv descriptorEnv
        );
}

"Default descriptor; if you need a custom [[Descriptor]], you would typically use it and use a custom [[delegate]] function
 for customisation.
 Example:
 
     shared class Complex(shared Float re, shared Float im) {}
     Descriptor descriptor = DefaultDescriptor (
        // delegate, tried first
        (Object? obj, DescriptorEnv descriptorEnv) {
            if(is Complex obj) {
                return \"\``obj.re.string\`` + \``obj.im.string\``i \";
            }
            return  null;
        }
     );
 
 Its behaviour may change in future (eg to improve readability). 
 "
by ("Jean-Pierre Ragey")
shared class DefaultDescriptor(
    "This function allows to customise object description: it will be called first by [[describe]], to get some (custom) object description.
     If it returns null, DefaultDescriptor will try other (default) methods to get the description.  
     "
    shared String ? (Object?, DescriptorEnv) delegate = (Object? obj, DescriptorEnv env) => null

) satisfies Descriptor {
    
    "Get a string description of obj. 
     The returned string is defined as follow:
     - call `delegate`(obj, descriptorEnv); if it returns a string, this string is returned;
     - if `obj` is a `String`, it is returned, enclosed in double-quotes;
     - if it's an `Iterable<Object>`, returns a comma-separated list of its elements descriptions (also obtained by describe()), enclosed in [];
     - if it's a non-null object, returns its `string` attribute;
     - otherwise returns \"&lt;null&gt;\". 
     "
    shared actual String describe(Object? obj, DescriptorEnv descriptorEnv) {
        
        if(exists s = delegate(obj, descriptorEnv)) {
            return s;
        }
        
        if(is String obj) {
            return "\"" + obj.string + "\"";
        }
        
        if(is Iterable<Object> obj, !obj.empty) {
            return "[" +  (", ".join{for(o in obj) describe(o, descriptorEnv)}) +"]";
        }
        
        return obj?.string else "<null>";
    }
}

