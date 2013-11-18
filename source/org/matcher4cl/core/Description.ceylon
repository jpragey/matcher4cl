
"Styles of output text.
 Usually error are highlighted in some way; success strings are left as-is."
by ("Jean-Pierre Ragey")
shared abstract class TextStyle() of highlighted |normalStyle {
}

"Style of text for error highlighting"
see (`class TextStyle`)
by ("Jean-Pierre Ragey")
shared object highlighted extends TextStyle() {}

"Style of text for success"
see (`class TextStyle`)
by ("Jean-Pierre Ragey")
shared object normalStyle extends TextStyle() {}

"Return style for 'success' boolean (true => [[normalStyle]], false = [[highlighted]]"
by ("Jean-Pierre Ragey")
shared TextStyle matchStyle(Boolean success) {
    if(success) {
        return normalStyle;
    }
    return highlighted;
}

"Get the maximum level of `descriptions`"
by ("Jean-Pierre Ragey")
Integer maxLevel({Description *} descriptions) {
    return descriptions.fold(0, (Integer partial, Description elem) => max{partial, elem.level});
}

"Footnote, too print large object descriptions after the mismatch description."
shared class FootNote(
    "Index for reference; footnotes are numbered as 0, 1, 2..."
    shared Integer reference, 
    "Description to be printed in footnote"
    shared Description description) {
}


shared interface DescriptionText of DescriptionTextLeaf| DescriptionTextNode {
    shared formal Integer singleLineSize;
}


"Text element, single line (or part of a single line [[DescriptionTextNode]]."
shared class DescriptionTextLeaf(shared TextStyle textStyle, shared String text) satisfies DescriptionText {
    shared actual Boolean equals(Object that) {
        if(is DescriptionTextLeaf that) {
            return text == that.text && textStyle == that.textStyle;
        } else {
            return false;
        }
    }
    
    shared actual Integer singleLineSize = text.size;
    
}
"May be split on several lines"
shared class DescriptionTextNode(
    // TODO: maybe should be a leaf ?
    shared DescriptionText/*Leaf*/? prefix, 
    shared [DescriptionText *] children
    
) satisfies DescriptionText 
{
    shared actual Boolean equals(Object that) {
        if(is DescriptionTextNode that) {
            variable Boolean prefixMatch = false;
            if(exists prefix, exists thatPrefix = that.prefix) {
                prefixMatch = (prefix == thatPrefix);
            }
            if(is Null prefix, is Null t = that.prefix) {
                prefixMatch = true;
            }
            return prefixMatch && children.equals(children);
        }
        return false;
    }
    
    variable Integer textSize = 0;
    if(exists prefix) {
        textSize = prefix.singleLineSize; 
    }
    for(dt in children) {
        textSize += dt.singleLineSize;
    }
    
    shared actual Integer singleLineSize = textSize;
    
}




"Description of match result.
 Descriptions are a tree structure explaining how expected and actual objects differ; they are typically created by [[Matcher]]s.
 Its main method is [[appendTo]], that dump the explanation text(s) to a StringBuilder.
 
 Descriptions are needed because matchers can't write directly the explanation texts: at matching time they ignore
 _how_ to write - eg if it's plain text or HTML.   
 "
by ("Jean-Pierre Ragey")
shared interface Description  
{
    
    "Append this description to `stringBuilder`, using `descrWriter` formatting."
    shared formal void appendTo(
        StringBuilder stringBuilder,
        "Defines _how_ to write: " 
        DescrWriter descrWriter,
        "Description node depth (0 for root)" 
        Integer depth,
        DescriptorEnv descriptorEnv);
    
    "Node level (roughly distance to deepest leaf, used for single line/multiline switching)"
    shared formal Integer level;
    
    "Convert this description to String, using `descrWriter` formatting."
    shared String toString(DescrWriter descrWriter, DescriptorEnv descriptorEnv = DefaultDescriptorEnv()) {
        StringBuilder sb = StringBuilder();
        appendTo(sb, descrWriter, 0 /*root level*/, descriptorEnv);
        String result = sb.string;
        return result; 
    }
    
    shared formal DescriptionText toDescriptionText(DescriptorEnv descriptorEnv);
}

"Description for 'simple' objects: value is converted to String by a [[Descriptor]]."
by ("Jean-Pierre Ragey")
shared class ValueDescription(
        "Style."
        TextStyle textStyle,
        "The value to describe." 
        Object? val, 
        "Descriptor used to convert `val` to a `String`; defaults to [[DefaultDescriptor]]."
        Descriptor descriptor= DefaultDescriptor()
        ) satisfies Description {

    "Always 0."
    shared actual Integer level = 0;
    
    shared actual void appendTo(StringBuilder stringBuilder, DescrWriter descrWriter, Integer depth, DescriptorEnv descriptorEnv) {
        String s = descriptor.describe(val, descriptorEnv);
        descrWriter.writeText(stringBuilder, textStyle, s);
    }
    
    //shared actual void visit(DescriptionVisitor visitor) {
    //    visitor.start(this);
    //    visitor.end(this);
    //}
    
    shared actual DescriptionText toDescriptionText(DescriptorEnv descriptorEnv) {
        String s = descriptor.describe(val, descriptorEnv);
        return DescriptionTextLeaf(textStyle, s);
    }
    
}

"Description consisting in a simple String."
by ("Jean-Pierre Ragey")
shared class StringDescription(
    "String value"
    String val,
    ""
    TextStyle textStyle = normalStyle 
) satisfies Description {
    "Always 0."
    shared actual Integer level = 0;
    
    "Append the value to stringBuilder"
    shared actual void appendTo(StringBuilder stringBuilder, DescrWriter descrWriter, Integer depth, DescriptorEnv descriptorEnv) {
        descrWriter.writeText(stringBuilder, textStyle, val);
    } 
    "Return the value ([val])"
    shared actual String string => val;
    
    shared actual DescriptionText toDescriptionText(DescriptorEnv descriptorEnv) {
        return DescriptionTextLeaf(textStyle, val);
    }
    //shared actual void visit(DescriptionVisitor visitor) {
    //    visitor.start(this);
    //    visitor.end(this);
    //}
}

"Concatenation of descriptions. Resulting text is the concatenation of description texts."
by ("Jean-Pierre Ragey")
shared class CatDescription(
    "The description whose string representations will be concatenated."
    {Description *} descriptions
) satisfies Description {
    
    "Node level: max node level of `descriptions`. CatDescription doesn't add any level."
    shared actual Integer level = maxLevel(descriptions);
    
    "Append all descriptions contents to stringBuilder."
    shared actual void appendTo(StringBuilder stringBuilder, DescrWriter descrWriter, Integer depth, DescriptorEnv descriptorEnv) {
        for(Description d in descriptions) {
            d.appendTo(stringBuilder, descrWriter, depth /*keep same depth*/, descriptorEnv);
        }
    } 
    
    shared actual String string {
        value sb = StringBuilder();
        for(d in descriptions) {sb.append(d.string);}
        return sb.string;
    }
    //shared actual void visit(DescriptionVisitor visitor) {
    //    visitor.start(this);
    //    visitor.end(this);
    //}
    shared actual DescriptionText toDescriptionText(DescriptorEnv descriptorEnv) {
        return DescriptionTextNode(null, {
            for(d in descriptions) d.toDescriptionText(descriptorEnv)
        }.sequence);
    }
}





//"Concatenation of descriptions, on a single line. Resulting text is the concatenation of description texts."
//by ("Jean-Pierre Ragey")
//shared class SingleLineCatDescription(
//    "The description whose string representations will be concatenated."
//    {SingleLineDescription *} descriptions
//) satisfies SingleLineDescription {
//    
//    "Node level: max node level of `descriptions`. CatDescription doesn't add any level."
//    shared actual Integer level = maxLevel(descriptions);
//    
//    "Append all descriptions contents to stringBuilder."
//    shared actual void appendTo(StringBuilder stringBuilder, DescrWriter descrWriter, Integer depth, DescriptorEnv descriptorEnv) {
//        for(Description d in descriptions) {
//            d.appendTo(stringBuilder, descrWriter, depth /*keep same depth*/, descriptorEnv);
//        }
//    } 
//    
//    shared actual String string {
//        value sb = StringBuilder();
//        for(d in descriptions) {sb.append(d.string);}
//        return sb.string;
//    }
//    //shared actual void visit(DescriptionVisitor visitor) {
//    //    visitor.start(this);
//    //    visitor.end(this);
//    //}
//}


"Description of matching result, eg '44', '42/45', 'ERR @2: 42/*45*.
 See [[appendTo]] for formatting details.
     "
by ("Jean-Pierre Ragey")
shared class MatchDescription(
    "Prefix, prepended to string representation."
    Description? prefix,
    "Style hint (string representation may not be wholy highlighted)"
    TextStyle textStyle, 
    "The expected value"
    Object? expectedObj, 
    "The actual value"
    Object? actualObj, 
    "The descriptor, used to convert `expectedObj` and `actualObj` to Strings."
    Descriptor descriptor = DefaultDescriptor(),
    "If true, write expected object; otherwise ignore it. Usually used with null expected object."
    Boolean writeExpected = true,
    "If true, write actual object; otherwise ignore it. Usually used with null actual object."
    Boolean writeActual = true
    ) satisfies Description 
{
    shared actual Integer level = 0;

    StringDescription separator = StringDescription("/"); 
    ValueDescription? actDescr = writeActual then ValueDescription(textStyle, actualObj, descriptor) else null;
    ValueDescription? expDescr = writeExpected then ValueDescription(normalStyle, expectedObj, descriptor) else null;
    
    "The message to append avoid duplicating actual and expected values. It is organized as follows:
     - if `prefix` is not null, it is added;
     - a string is created for actual value, if `writeActual` is true; otherwise it is empty;
     - a string is created for expected value, if `writeExpected` is true; otherwise it is empty;
     - if actual and expected values strings are equal, it is added; otherwise both are added,
       with a separator character (a slash).
     
     Note that the output value doesn't care if *values* match, it checks only their string representations;
     thus for Float you may get '0.99999999/1.0' even if the matcher decides they are the same.
     "
    shared actual void appendTo(StringBuilder stringBuilder, DescrWriter descrWriter, Integer depth, DescriptorEnv descriptorEnv) {
        
        if(exists prefix) {
            prefix.appendTo(stringBuilder, descrWriter, depth, descriptorEnv);
        }
        
        StringBuilder sb = StringBuilder();
        variable String actString = "";
        variable String expString = "";
        
        if(exists actDescr /*writeActual*/) {
            //ValueDescription actDescr = ValueDescription(textStyle, actualObj, descriptor);
            actDescr.appendTo(sb, descrWriter, depth + 1, descriptorEnv);
            actString = sb.string;
        }
        sb.reset();
        
        if(exists expDescr /*writeExpected*/) {
            //ValueDescription expDescr = ValueDescription(normalStyle, expectedObj, descriptor);
            expDescr.appendTo(sb, descrWriter, depth + 1, descriptorEnv);
            expString = sb.string;
        }
        
        if(actString == expString) {     // Don't repeat
            stringBuilder.append(actString);
        } else {                        // Values match but with different string representations
            stringBuilder.appendAll{expString, "/", actString};
        }
    }
    
    //shared actual void visit(DescriptionVisitor visitor) {
    //    visitor.start(this);
    //    
    //    if(exists prefix) {
    //        prefix.visit(visitor);
    //    }
    //    
    //    if(exists actDescr, exists expDescr) {
    //        if(actDescr == expDescr) {  // Don't repeat
    //            actDescr.visit(visitor);
    //        } else {
    //            expDescr.visit(visitor);
    //            separator.visit(visitor);
    //            actDescr.visit(visitor);
    //        }
    //    } else if(exists actDescr) {
    //        actDescr.visit(visitor);
    //    } else if(exists expDescr) {
    //        expDescr.visit(visitor);
    //    }
    //    
    //    visitor.end(this);
    //}
    shared actual DescriptionText toDescriptionText(DescriptorEnv descriptorEnv) {
        
        variable DescriptionText? prefixDText = null;
        if(exists prefix) {
            prefixDText = prefix.toDescriptionText(descriptorEnv);
        }
        DescriptionText? actualDText = writeActual 
            then ValueDescription(textStyle, actualObj, descriptor).toDescriptionText(descriptorEnv) 
            else null; 
        DescriptionText? expectedDText = writeExpected 
            then ValueDescription(textStyle, expectedObj, descriptor).toDescriptionText(descriptorEnv) 
            else null; 
        
        if(exists actualDText, exists expectedDText) {
             
            if(actualDText == expectedDText) {  // Don't repeat
                return DescriptionTextNode(prefixDText, [actualDText]);
            } else {
                return DescriptionTextNode(prefixDText, [
                    actualDText,
                    DescriptionTextLeaf(normalStyle, "/"),
                    expectedDText
                ]);
            }
        }
        return DescriptionTextNode(prefixDText, []);
    }
    
}



"Description with children (lists, maps, objects, etc).
 May be printed on several lines.
 "
by ("Jean-Pierre Ragey")
shared class CompoundDescription(
    "Prefix (eg mimatch explanation), if not null."
    Description? prefixDescription,
    "Elements commons to expected and actual lists."
    Description[] commonElementDescrs,
    "Expected elements that are not in actual list"
    Description[] extraExpectedDescrs = {},
    "Actual elements that are not in expected list"
    Description[] extraActualDescrs = {},
    "Nodes at levels higher than `singleLineLevel` will be written on several lines (if the text format allows it)."
    Integer singleLineLevel = 1
) satisfies Description {
    
    shared actual Integer level = max{maxLevel(commonElementDescrs), maxLevel(extraExpectedDescrs), maxLevel(extraActualDescrs)} + 1;
    
    void appendList(StringBuilder stringBuilder, DescrWriter descrWriter, Description? prefix, {Description*} descriptions, Integer depth, DescriptorEnv descriptorEnv) {
        
        Boolean multiline = level > singleLineLevel;
        
        // -- First line: <indent> prefix '{'
        if(exists prefix) {
            prefix.appendTo(stringBuilder, descrWriter, depth, descriptorEnv);
            descrWriter.writeText(stringBuilder, normalStyle, " ");
        }
        descrWriter.writeText(stringBuilder, normalStyle, "{");
        
        // -- Element lines: <indent+1> element ','?  
        variable Boolean first = true;
        for(d in descriptions) {

            if(!first) {
                descrWriter.writeText(stringBuilder, normalStyle, ", ");
            }
            if(multiline) {
                descrWriter.writeNewLineIndent(stringBuilder, depth+1);
            }
            d.appendTo(stringBuilder, descrWriter, depth+1, descriptorEnv);
            
            first = false;
        }
        
        // -- End lines: <indent> '}'  
        if(multiline) {
            descrWriter.writeNewLineIndent(stringBuilder, depth);
        }
        descrWriter.writeText(stringBuilder, normalStyle, "}");
    }

    void writeOptList(Description[] descrs, StringBuilder stringBuilder, DescrWriter descrWriter, Description description/* Formatter formatter*/, Integer depth, DescriptorEnv descriptorEnv) {
        if(nonempty descrs) {
            descrWriter.writeNewLineIndent(stringBuilder, depth);
            appendList(stringBuilder, descrWriter, description, descrs, depth, descriptorEnv);
        }    
    }
    
    shared actual void appendTo(StringBuilder stringBuilder, DescrWriter descriptionWriter, Integer depth, DescriptorEnv descriptorEnv) {

        appendList(stringBuilder, descriptionWriter, prefixDescription, commonElementDescrs, depth, descriptorEnv);

        // -- Extra expected elements
        writeOptList(extraExpectedDescrs, stringBuilder, descriptionWriter, StringDescription(" => ERR ``extraExpectedDescrs.size`` expected not in actual list: "), depth, descriptorEnv);
        writeOptList(extraActualDescrs, stringBuilder, descriptionWriter, StringDescription(" => ERR ``extraActualDescrs.size`` actual not in expected list: "), depth, descriptorEnv);
    }
    
    
    
    
    
    // ***********************************************
    DescriptionTextNode appendDList(DescriptionText? prefix, {Description*} descriptions, DescriptorEnv descriptorEnv) {
        //variable DescriptionText? prefixDText = null;
        //if(exists prefix) {
        //    prefixDText = prefix.toDescriptionText(descriptorEnv);
        //}
        
        variable Boolean first = true;
        value descrTextBuilder = SequenceBuilder<DescriptionText>();
        descrTextBuilder.append(DescriptionTextLeaf(normalStyle, "{"));
        
        for(d in descriptions) {
            
            DescriptionText descriptionText = d.toDescriptionText(descriptorEnv);
            descrTextBuilder.append(descriptionText);
            
            if(first) {
                first = false;
            } else {
                descrTextBuilder.append(DescriptionTextLeaf(normalStyle, ","));
            }
        }
        
        descrTextBuilder.append(DescriptionTextLeaf(normalStyle, "}"));
        return DescriptionTextNode(prefix, descrTextBuilder.sequence);
        
    }
    
    shared actual DescriptionText toDescriptionText(DescriptorEnv descriptorEnv) {
        variable DescriptionText? prefixDText = null;
        if(exists prefixDescription) {
            prefixDText = prefixDescription.toDescriptionText(descriptorEnv);
        }
        value descrTextBuilder = SequenceBuilder<DescriptionText>();
        
        DescriptionTextNode commons = appendDList(prefixDText, commonElementDescrs, descriptorEnv);
        descrTextBuilder.append(commons);
        //return DescriptionTextNode
        
        if(nonempty extraExpectedDescrs) {
            DescriptionTextNode extraExpected = appendDList(
                DescriptionTextLeaf(highlighted, " => ERR ``extraExpectedDescrs.size`` expected not in actual list: "), 
                extraExpectedDescrs, descriptorEnv);
            descrTextBuilder.append(extraExpected);
        }
        if(nonempty extraActualDescrs) {
            DescriptionTextNode extraActual = appendDList(
                DescriptionTextLeaf(highlighted, " => ERR ``extraActualDescrs.size`` actual not in expected list: "), 
                extraActualDescrs, descriptorEnv);
            descrTextBuilder.append(extraActual);
        }
        
        return DescriptionTextNode(null /*prefix*/, descrTextBuilder.sequence);

        
    }
    
}

shared class TreeDescription(
    "Node description."
    Description description,
    "Subnodes descriptions."
    {Description*} children
) satisfies Description {
    
    shared actual Integer level = maxLevel(children) + 1;
    
    void appendList(StringBuilder stringBuilder, DescrWriter descrWriter, Description nodeDescription, {Description*} descriptions, Integer depth, DescriptorEnv descriptorEnv) {
        
        nodeDescription.appendTo(stringBuilder, descrWriter, depth, descriptorEnv);
        
        for(d in descriptions) {
            descrWriter.writeNewLineIndent(stringBuilder, depth+1);
            d.appendTo(stringBuilder, descrWriter, depth+1, descriptorEnv);
        }
    }

    shared actual void appendTo(StringBuilder stringBuilder, DescrWriter descrWriter, Integer depth, DescriptorEnv descriptorEnv) {
        appendList(stringBuilder, descrWriter, description, children, depth, descriptorEnv);
    }
    
    shared actual DescriptionText toDescriptionText(DescriptorEnv descriptorEnv) {
        return DescriptionTextNode {
            prefix = description.toDescriptionText(descriptorEnv);
            children = {for(d in children) d.toDescriptionText(descriptorEnv)}.sequence;
        };
    }
}

"List description, as created by [[ListMatcher]].
 As actual and expected lists length may differ, it also holds 
 lists of elements from a list not found in the other one. 
     "
by ("Jean-Pierre Ragey")
shared class ListDescription(
    "Explaination of mismatch, if not null."
    Description? failureDescription,
    "Elements commons to expected and actual lists."
    Description[] commonDescrs,
    "Expected elements that are not in actual list"
    Description[] extraExpected = [],
    "Actual elements that are not in expected list"
    Description[] extraActual = []
    ) extends CompoundDescription(failureDescription, commonDescrs, extraExpected, extraActual) 
{
}

"'A->B' or 'A->B/C' map entry description"
by ("Jean-Pierre Ragey")
shared class MapEntryDescription(
    Description keyDescr, 
    Description valueDescr) satisfies Description {
    
    shared actual Integer level = maxLevel{keyDescr, valueDescr};
    
    shared actual void appendTo(StringBuilder stringBuilder, DescrWriter descrWriter, Integer depth, DescriptorEnv descriptorEnv) {
        keyDescr.appendTo(stringBuilder, descrWriter, depth + 1, descriptorEnv);
        descrWriter.writeText(stringBuilder, normalStyle, "->");
        valueDescr.appendTo(stringBuilder, descrWriter, depth + 1, descriptorEnv);
    }
    
    shared actual DescriptionText toDescriptionText(DescriptorEnv descriptorEnv) {
        return DescriptionTextNode {
            prefix = null;
            children = [
                keyDescr.toDescriptionText(descriptorEnv),
                DescriptionTextLeaf(normalStyle, "->"),
                valueDescr.toDescriptionText(descriptorEnv)
            ];
        };
    }
}

"Map matching description, as created by [[MapMatcher]].
 Entries with matching keys must be passed in `commonDescrs` (associated expected/actual values may differ);
 entries whose keys are found only in actual or expected maps must be
 stored in [[extraActualDescrs]] and [[extraExpectedDescrs]].  
  
 It is basically a list of 'common' [[MapEntryDescription]]s, with matching keys.
 
 As actual and expected maps sizes may differ, it also holds 
 lists of entries from a list not found in the other one. 
     "
by ("Jean-Pierre Ragey")
shared class MapDescription (
    Description ? failureDescription,
    "Common entries descriptions: entry keys always match, but values may differ."
    MapEntryDescription[] commonDescrs,
    "Actual entries whose keys are not in expected."
    MapEntryDescription[] extraActualDescrs = [],
    "Expected entries whose keys are not in actual."
    MapEntryDescription[] extraExpectedDescrs = []

    ) extends CompoundDescription(failureDescription, commonDescrs, extraExpectedDescrs, extraActualDescrs) 
{
}

"Custom object field description, format: \"&lt;field name&gt;: (&lt;value&gt;)\""
by ("Jean-Pierre Ragey")
shared class ObjectFieldDescription(
    "Object field name"
    String fieldName,
    "Object field value"
    Description valueDescription
    ) satisfies Description
{
    "Same level as `valueDescription`"
    shared actual Integer level = valueDescription.level;
    
    shared actual void appendTo(StringBuilder stringBuilder, DescrWriter descrWriter, Integer depth, DescriptorEnv descriptorEnv) {
        
        descrWriter.writeText(stringBuilder, normalStyle, fieldName);
        descrWriter.writeText(stringBuilder, normalStyle, ": (");
        valueDescription.appendTo(stringBuilder, descrWriter, depth+1, descriptorEnv);
        descrWriter.writeText(stringBuilder, normalStyle, ")");
    }
    
    shared actual DescriptionText toDescriptionText(DescriptorEnv descriptorEnv) {
        return DescriptionTextNode {
            prefix = null;
            children = [
                DescriptionTextLeaf(normalStyle, fieldName),
                DescriptionTextLeaf(normalStyle, ": ("),
                valueDescription.toDescriptionText(descriptorEnv),
                DescriptionTextLeaf(normalStyle, ": )")
            ];
        };
    }
}

"Custom object description.
 It is made of a prefix (describes the object itself) and a list 
 of [[ObjectFieldDescription]], which describe its fields.
 "
see (`class ObjectMatcher`)     
by ("Jean-Pierre Ragey")
shared class ObjectDescription (
    "Prefix, prepended to object description"
    Description? prefix,
    "Custom object fields"
    ObjectFieldDescription[] fields
    ) extends CompoundDescription(prefix, fields) 
{ 
}

"Child description (to be used with [[CompoundDescription]]).
 It's simply a wrapper on another [[Description]]; it adds a prefix to output string, 
 so that children descriptions can be differenciated."
see (`class CompoundDescription`)
by ("Jean-Pierre Ragey")
shared class ChildDescription (
    "Prefix, typically child matcher name (for compound matchers like `AllMatcher`)"
    Description prefix,
    "The description to wrap"
    Description description
        ) satisfies Description
{
    "Same level as wrapped description."
    shared actual Integer level = description.level;
    
    "Append to `stringBuilder` the prefix, the \": \" string, and the wrapped description."
    shared actual void appendTo(StringBuilder stringBuilder, DescrWriter descrWriter, Integer depth, DescriptorEnv descriptorEnv) {
        prefix.appendTo(stringBuilder, descrWriter, depth+1, descriptorEnv);
        descrWriter.writeText(stringBuilder, normalStyle, ": ");
        description.appendTo(stringBuilder, descrWriter, depth+1, descriptorEnv);
    }
    
    shared actual DescriptionText toDescriptionText(DescriptorEnv descriptorEnv) {
        return DescriptionTextNode {
            prefix = null;
            children = [
                prefix.toDescriptionText(descriptorEnv),
                DescriptionTextLeaf(normalStyle, ": "),
                description.toDescriptionText(descriptorEnv)
            ];
        };
    }
}

