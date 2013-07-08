
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

"Default descriptor:
 - null is written as \"&lt;null&gt;\";
 - Strings are enclosed in double-quotes;
 - otherwise the object `string` propert is returned.
 This may change in future (eg to improve readability). 
 "
by ("Jean-Pierre Ragey")
shared class DefaultDescriptor(

    shared String ? (Object?, DescriptorEnv) delegate = (Object? obj, DescriptorEnv env) => null


) satisfies Descriptor {
    
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

