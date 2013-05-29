
doc "Message formatter: converts a list of parameters to a String, in an implementation-dependant way."
see ("FormattedDescription","DefaultFormatter")
by "Jean-Pierre Ragey"
shared interface Formatter {
    doc "Message parameters. Their use in messages is implementation-dependant."
    shared formal String toString([Object *] parameters, DescriptorEnv descriptorEnv);
}


doc "Default Formatter implementation.
     It use a simple templating scheme: the `template` string is copied, with '{}' substrings replaced by successive parameters.
     Characters enclosed between '{' and '}' are ignored, but this may change in future.
     
     Parameters are converted to Strings by `descriptor`.
     "
by "Jean-Pierre Ragey"
shared class DefaultFormatter(
    doc "The template string."
    String template,
    doc "Converts parameters to strings."
    Descriptor descriptor  = DefaultDescriptor()
    ) satisfies Formatter 
{
    interface TemplatePart {
        shared formal void append(StringBuilder stringBuilder, [Object *] parameters, DescriptorEnv descriptorEnv);
    }

    class StringTemplatePart(String part) satisfies TemplatePart {
        shared actual void append(StringBuilder stringBuilder, [Object *] parameters, DescriptorEnv descriptorEnv) {
            stringBuilder.append(part);
        }
    }
    
    class ParameterTemplatePart(Integer paramIndex, String(Object, DescriptorEnv) part) satisfies TemplatePart {
        shared actual void append(StringBuilder stringBuilder, [Object *] parameters, DescriptorEnv descriptorEnv) {
            Object? param = parameters[paramIndex];
            assert(exists param);
            String s = part(param, descriptorEnv);
            stringBuilder.append(s);
        }
    }
    
    TemplatePart[] splitTemplate() {
        variable Integer paramIndex = 0;
        variable Boolean insideParameter = false;
        variable StringBuilder sb = StringBuilder();
        SequenceBuilder<TemplatePart> templateParts = SequenceBuilder<TemplatePart>(); 
        
        for(Character c in template) {
            
            if(c == '{') {  // start parameter
                doc ("Nested parameters not supported: ``template``");
                assert (!insideParameter);
                insideParameter = true;
                if(sb.size >0) {
                    templateParts.append(StringTemplatePart(sb.string));
                    sb.reset();
                }
                
            } else if(c == '}') { //end of parameter
                doc "Found '}' without '{'"
                assert (insideParameter);
                insideParameter = false;
                
                String(Object, DescriptorEnv) part = (Object o, DescriptorEnv descriptorEnv) =>  descriptor.describe(o, descriptorEnv); 
                templateParts.append(ParameterTemplatePart(paramIndex, part));
                sb.reset();
                paramIndex++;
                
            } else {        // normal char (inside or outside parameter
                sb.appendCharacter(c);
            }
            
        }
        // -- Append last template part, if any
        doc ("End of template inside a parameter, '}' expected : ``template``");
        assert (!insideParameter);
        if(sb.size >0) {
            templateParts.append(StringTemplatePart(sb.string));
        }
        
        return templateParts.sequence;
    }
    
    TemplatePart[] templateParts = splitTemplate();
    
    doc "Convert template to string, replacing all '{}' by successive parameters."
    shared actual String toString([Object *] parameters, DescriptorEnv descriptorEnv) {
        StringBuilder sb = StringBuilder();
        for(TemplatePart tp in templateParts) {
            tp.append(sb, parameters, descriptorEnv);
        }
        String result = sb.string;
        return result;
    }
    
}

