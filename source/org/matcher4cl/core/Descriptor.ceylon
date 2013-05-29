
doc "Descriptor environment"
shared interface DescriptorEnv {
    doc "Create a new FootNote"
    shared formal FootNote newFootNote(Description description);
 
}

doc "Default descriptor environment.
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
    doc "Get current footnote list."
    shared {FootNote*} footNotes() {
        return footNotesBuilder.sequence;
    }
}

doc "Convert a simple object to a String, used for description to string conversion."
see "`ValueDescription`"
by "Jean-Pierre Ragey"
shared interface Descriptor {
    doc "Return a short decsription of `obj`. "
    shared formal String describe(
        doc "The object to describe"
        Object? obj,
        doc "Utilities for description (eg footnotes)" 
        DescriptorEnv descriptorEnv);
}

doc "Default descriptor:
     - null is written as \"&lt;null&gt;\";
     - Strings are enclosed in double-quotes;
     - otherwise the object `string` propert is returned.
     This may change in future (eg to improve readability). 
     "
by "Jean-Pierre Ragey"
shared class DefaultDescriptor() satisfies Descriptor {
    
    shared actual String describe(Object? obj, DescriptorEnv descriptorEnv) {
        
        if(is String obj) {
            return "\"" + obj.string + "\"";
        }
        
        return obj?.string else "<null>";
    }
}

