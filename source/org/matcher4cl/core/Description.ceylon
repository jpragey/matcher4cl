
doc "Styles of output text.
     Usually error are highlighted in some way; success strings are left as-is."
by "Jean-Pierre Ragey"
shared abstract class TextStyle() of highlighted |normalStyle {
}

doc "Style of text for error highlighting"
see "HighlightStyle"
by "Jean-Pierre Ragey"
shared object highlighted extends TextStyle() {}

doc "Style of text for success"
see "HighlightStyle"
by "Jean-Pierre Ragey"
shared object normalStyle extends TextStyle() {}

doc "Return style for 'success' boolean (true => [[normalStyle]], false = [[highlighted]]"
by "Jean-Pierre Ragey"
shared TextStyle matchStyle(Boolean success) {
    if(success) {
        return normalStyle;
    }
    return highlighted;
}

doc "Get the maximum level of `descriptions`"
by "Jean-Pierre Ragey"
Integer maxLevel({Description *} descriptions) {
    return descriptions.fold(0, (Integer partial, Description elem) => max{partial, elem.level});
}

doc "Footnote, too print large object descriptions after the mismatch description."
shared class FootNote(
    doc "Index for reference; footnotes are numbered as 0, 1, 2..."
    shared Integer reference, 
    doc "Description to be printed in footnote"
    shared Description description) {
}

doc "Description of match result."
by "Jean-Pierre Ragey"
shared interface Description  
{
    
    doc "Append this description to `stringBuilder`, using `textFormat` formatting."
    shared formal void appendTo(
        StringBuilder stringBuilder, 
        TextFormat textFormat,
        doc "Description node depth (0 for root)" 
        Integer depth,
        DescriptorEnv descriptorEnv);
    
    doc "Node level (roughly distance to deepest leaf, used for single line/multiline switching)"
    shared formal Integer level;
    
    doc "Convert this description to String, using `textFormat` formatting."
    shared String toString(TextFormat textFormat, DescriptorEnv descriptorEnv = DefaultDescriptorEnv()) {
        StringBuilder sb = StringBuilder();
        appendTo(sb, textFormat, 0 /*root level*/, descriptorEnv);
        String result = sb.string;
        return result; 
    }
}

doc "Description for 'simple' objects: value is converted to String by a [[Descriptor]]."
by "Jean-Pierre Ragey"
shared class ValueDescription(
        doc "Style."
        TextStyle textStyle,
        doc "The value to describe." 
        Object? val, 
        doc "Descriptor used to convert `val` to a `String`; defaults to [[DefaultDescriptor]]."
        Descriptor descriptor= DefaultDescriptor()
        ) satisfies Description {

    doc "Always 0."
    shared actual Integer level = 0;
    
    shared actual void appendTo(StringBuilder stringBuilder, TextFormat textFormat, Integer depth, DescriptorEnv descriptorEnv) {
        String s = descriptor.describe(val, descriptorEnv);
        textFormat.writeText(stringBuilder, textStyle, s);
    } 
}

doc "Description consisting in a simple String."
by "Jean-Pierre Ragey"
shared class StringDescription(
    String val,
    TextStyle textStyle = normalStyle 
) satisfies Description {

    shared actual Integer level = 0;
    
    shared actual void appendTo(StringBuilder stringBuilder, TextFormat textFormat, Integer depth, DescriptorEnv descriptorEnv) {
        textFormat.writeText(stringBuilder, textStyle, val);
    } 
}

doc "Concatenation of descriptions. Resulting text is the concatenation of description texts."
by "Jean-Pierre Ragey"
shared class CatDescription(
    doc "The description whose string representations will be concatenated."
    {Description *} descriptions
) satisfies Description {

    doc "Node level: max node level of `descriptions`. CatDescription doesn't add any level."
    shared actual Integer level = maxLevel(descriptions);
    
    doc "Append all descriptions contents to stringBuilder."
    shared actual void appendTo(StringBuilder stringBuilder, TextFormat textFormat, Integer depth, DescriptorEnv descriptorEnv) {
        for(Description d in descriptions) {
            d.appendTo(stringBuilder, textFormat, depth /*keep same depth*/, descriptorEnv);
        }
    } 
}


doc "Description of matching result, eg '44', '42/45', 'ERR @2: 42/*45*.
     See [[appendTo]] for formatting details.
     "
by "Jean-Pierre Ragey"
shared class MatchDescription(
    doc "Prefix, prepended to string representation."
    Description? prefix,
    doc "Style hint (string representation may not be wholy highlighted)"
    TextStyle textStyle, 
    doc "The expected value"
    Object? expectedObj, 
    doc "The actual value"
    Object? actualObj, 
    doc "The descriptor, used to convert `expectedObj` and `actualObj` to Strings."
    Descriptor descriptor = DefaultDescriptor(),
    doc "If true, write expected object; otherwise ignore it. Usually used with null expected object."
    Boolean writeExpected = true,
    doc "If true, write actual object; otherwise ignore it. Usually used with null actual object."
    Boolean writeActual = true
    ) satisfies Description {

    shared actual Integer level = 0;
    
    doc "The message to append avoid duplicating actual and expected values. It is organized as follows:
         - if `prefix` is not null, it is added;
         - a string is created for actual value, if `writeActual` is true; otherwise it is empty;
         - a string is created for expected value, if `writeExpected` is true; otherwise it is empty;
         - if actual and expected values strings are equal, it is added; otherwise both are added,
           with a separator character (a slash).
         
         Note that the output value doesn't care if *values* match, it checks only their string representations;
         thus for Float you may get '0.99999999/1.0' even if the matcher decides they are the same.
         "
    shared actual void appendTo(StringBuilder stringBuilder, TextFormat textFormat, Integer depth, DescriptorEnv descriptorEnv) {
        
        if(exists prefix) {
            prefix.appendTo(stringBuilder, textFormat, depth, descriptorEnv);
        }
        
        StringBuilder sb = StringBuilder();
        variable String actString = "";
        variable String expString = "";
        
        if(writeActual) {
            ValueDescription actDescr = ValueDescription(textStyle, actualObj, descriptor);
            actDescr.appendTo(sb, textFormat, depth + 1, descriptorEnv);
            actString = sb.string;
        }
        sb.reset();
        
        if(writeExpected) {
            ValueDescription expDescr = ValueDescription(normalStyle, expectedObj, descriptor);
            expDescr.appendTo(sb, textFormat, depth + 1, descriptorEnv);
            expString = sb.string;
        }
        
        if(actString == expString) {     // Don't repeat
            stringBuilder.append(actString);
        } else {                        // Values match but with different string representations
            stringBuilder.appendAll{expString, "/", actString};
        }
    }
}



doc "Description with children (lists, maps, objects, etc).
     May be printed on several lines.
     "
by "Jean-Pierre Ragey"
shared class CompoundDescription(
    doc "Prefix (eg mimatch explanation), if not null."
    Description? prefixDescription,
    doc "Elements commons to expected and actual lists."
    [Description*] commonElementDescrs,
    doc "Expected elements that are not in actual list"
    [Description*] extraExpectedDescrs = {},
    doc "Actual elements that are not in expected list"
    [Description*] extraActualDescrs = {},
    doc "Nodes at levels higher than `singleLineLevel` will be written on several lines (if the text format allows it)."
    Integer singleLineLevel = 1
) satisfies Description {
    
    shared actual Integer level = max{maxLevel(commonElementDescrs), maxLevel(extraExpectedDescrs), maxLevel(extraActualDescrs)} + 1;
    
    void appendList(StringBuilder stringBuilder, TextFormat textFormat, Description? prefix, {Description*} descriptions, Integer depth, DescriptorEnv descriptorEnv) {
        
        Boolean multiline = level > singleLineLevel;
        
        // -- First line: <indent> prefix '{'
        if(exists prefix) {
            prefix.appendTo(stringBuilder, textFormat, depth, descriptorEnv);
            textFormat.writeText(stringBuilder, normalStyle, " ");
        }
        textFormat.writeText(stringBuilder, normalStyle, "{");
        
        // -- Element lines: <indent+1> element ','?  
        variable Boolean first = true;
        for(d in descriptions) {

            if(!first) {
                textFormat.writeText(stringBuilder, normalStyle, ", ");
            }
            if(multiline) {
                textFormat.writeNewLineIndent(stringBuilder, depth+1);
            }
            d.appendTo(stringBuilder, textFormat, depth+1, descriptorEnv);
            
            first = false;
        }
        
        // -- End lines: <indent> '}'  
        if(multiline) {
            textFormat.writeNewLineIndent(stringBuilder, depth);
        }
        textFormat.writeText(stringBuilder, normalStyle, "}");
    }

    void writeOptList([Description*] descrs, StringBuilder stringBuilder, TextFormat textFormat, Description description/* Formatter formatter*/, Integer depth, DescriptorEnv descriptorEnv) {
        if(nonempty descrs) {
            textFormat.writeNewLineIndent(stringBuilder, depth);
            appendList(stringBuilder, textFormat, description, descrs, depth, descriptorEnv);
        }    
    }
    
    shared actual void appendTo(StringBuilder stringBuilder, TextFormat descriptionWriter, Integer depth, DescriptorEnv descriptorEnv) {

        appendList(stringBuilder, descriptionWriter, prefixDescription, commonElementDescrs, depth, descriptorEnv);

        // -- Extra expected elements
        writeOptList(extraExpectedDescrs, stringBuilder, descriptionWriter, StringDescription(" => ERR ``extraExpectedDescrs.size`` expected not in actual list: "), depth, descriptorEnv);
        writeOptList(extraActualDescrs, stringBuilder, descriptionWriter, StringDescription(" => ERR ``extraActualDescrs.size`` actual not in expected list: "), depth, descriptorEnv);
    }
}

shared class TreeDescription(
    doc "Node description."
    Description description,
    doc "Subnodes descriptions."
    [Description*] commonElementDescrs
) satisfies Description {
    
    shared actual Integer level = maxLevel(commonElementDescrs) + 1;
    
    void appendList(StringBuilder stringBuilder, TextFormat textFormat, Description nodeDescription, {Description*} descriptions, Integer depth, DescriptorEnv descriptorEnv) {
        
        nodeDescription.appendTo(stringBuilder, textFormat, depth, descriptorEnv);
        
        for(d in descriptions) {
            textFormat.writeNewLineIndent(stringBuilder, depth+1);
            d.appendTo(stringBuilder, textFormat, depth+1, descriptorEnv);
        }
    }

    shared actual void appendTo(StringBuilder stringBuilder, TextFormat textFormat, Integer depth, DescriptorEnv descriptorEnv) {
        appendList(stringBuilder, textFormat, description, commonElementDescrs, depth, descriptorEnv);
    }
}

doc "List description, as created by [[ListMatcher]].
     As actual and expected lists length may differ, it also holds 
     lists of elements from a list not found in the other one. 
     "
by "Jean-Pierre Ragey"
shared class ListDescription(
    doc "Explaination of mismatch, if not null."
    Description? failureDescription,
    doc "Elements commons to expected and actual lists."
    [Description*] commonDescrs,
    doc "Expected elements that are not in actual list"
    [Description*] extraExpected = [],
    doc "Actual elements that are not in expected list"
    [Description*] extraActual = []
    ) extends CompoundDescription(failureDescription, commonDescrs, extraExpected, extraActual) 
{
}

doc "'A->B' or 'A->B/C' map entry description"
by "Jean-Pierre Ragey"
shared class MapEntryDescription(
    Description keyDescr, 
    MatchDescription valueDescr) satisfies Description {
    
    shared actual Integer level = maxLevel{keyDescr, valueDescr};
    
    shared actual void appendTo(StringBuilder stringBuilder, TextFormat textFormat, Integer depth, DescriptorEnv descriptorEnv) {
        keyDescr.appendTo(stringBuilder, textFormat, depth + 1, descriptorEnv);
        textFormat.writeText(stringBuilder, normalStyle, "->");
        valueDescr.appendTo(stringBuilder, textFormat, depth + 1, descriptorEnv);
    }
}

doc "Map matching description, as created by [[MapMatcher]].
     Entries with matching keys must be passed in `commonDescrs` (associated expected/actual values may differ);
     entries whose keys are found only in actual or expected maps must be
     stored in [[extraActualDescrs]] and [[extraExpectedDescrs]].  
      
     It is basically a list of 'common' [[MapEntryDescription]]s, with matching keys.
     
     As actual and expected maps sizes may differ, it also holds 
     lists of entries from a list not found in the other one. 
     "
by "Jean-Pierre Ragey"
shared class MapDescription (
    Description ? failureDescription,
    doc "Common entries descriptions: entry keys always match, but values may differ."
    [MapEntryDescription *] commonDescrs,
    doc "Actual entries whose keys are not in expected."
    [MapEntryDescription *] extraActualDescrs = [],
    doc "Expected entries whose keys are not in actual."
    [MapEntryDescription *] extraExpectedDescrs = []

    ) extends CompoundDescription(failureDescription, commonDescrs, extraExpectedDescrs, extraActualDescrs) 
{
}

doc "Custom object field description, format: \"&lt;field name&gt;: (&lt;value&gt;)\""
by "Jean-Pierre Ragey"
shared class ObjectFieldDescription(
    doc "Object field name"
    String fieldName,
    doc "Object field value"
    Description valueDescription
    ) satisfies Description
{
    doc "Same level as `valueDescription`"
    shared actual Integer level = valueDescription.level;
    
    shared actual void appendTo(StringBuilder stringBuilder, TextFormat textFormat, Integer depth, DescriptorEnv descriptorEnv) {
        
        textFormat.writeText(stringBuilder, normalStyle, fieldName);
        textFormat.writeText(stringBuilder, normalStyle, ": (");
        valueDescription.appendTo(stringBuilder, textFormat, depth+1, descriptorEnv);
        textFormat.writeText(stringBuilder, normalStyle, ")");
    }
}

doc "Custom object description.
     It is made of a prefix (describes the object itself) and a list 
     of [[ObjectFieldDescription]], which describe its fields.
     "
see "ObjectMatcher"     
by "Jean-Pierre Ragey"
shared class ObjectDescription (
    doc "Prefix, prepended to object description"
    Description? prefix,
    doc "Custom object fields"
    [ObjectFieldDescription*] fields
    ) extends CompoundDescription(prefix, fields) 
{ 
}

doc "Child description (to be used with [[CompoundDescription]]).
     It's simply a wrapper on another [[Description]]; it append a prefix to output string, 
     so that children descriptions can be differenciated."
see "CompoundDescription"
by "Jean-Pierre Ragey"
shared class ChildDescription (
    doc "Prefix, typically child matcher name (for compound matchers like `AllMatcher`)"
    Description prefix,
    doc "The description to wrap"
    Description description,
    doc "Descriptor for expected/actual entries keys and values"
    Descriptor entryDescriptor = DefaultDescriptor()
    
        ) satisfies Description
{
    doc "Same level as wrapped description."
    shared actual Integer level = description.level;
    
    doc "Append to `stringBuilder` the prefix, the \": \" string, and the wrapped description."
    shared actual void appendTo(StringBuilder stringBuilder, TextFormat textFormat, Integer depth, DescriptorEnv descriptorEnv) {
        prefix.appendTo(stringBuilder, textFormat, depth+1, descriptorEnv);
        textFormat.writeText(stringBuilder, normalStyle, ": ");
        description.appendTo(stringBuilder, textFormat, depth+1, descriptorEnv);
    }
}

