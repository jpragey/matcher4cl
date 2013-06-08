doc "Matcher library for Ceylon.
     
     # 5 mn introduction
     A matcher is an object that checks that another object is 'equal' to a predefined value. 
     Its most common usage is probably testing, when the actual result of an expression must match an expected value,
     otherwise an exception is thrown, carrying some meaningfull mismatch description.
     So let's go:
     
         import org.matcher4cl.core { assertThat, Is }
         void doTest() {
            assertThat (\"The actual value\", Is(\"The expected one\"));
         }
     
     Run it as a usual ceylon application, and you'll get  an exception stating:
         \"The expected one\"/<<<\"The actual value\">>>: expected[4]='e'(101=#65) != actual[4]='a'(97=#61)
     
     The \"&lt;&lt;&lt; &gt;&gt;&gt;\" is ASCII art for highlighting; the string matcher describe the first mismatching character, convenient 
     for differentiating non conventional chars (eg space (#20) and non-breaking space (#A0)).  
      
     In Eclipse, you can run it as a usual Ceylon test, if the ceylon test plugin is installed.
     
     The basic usage pattern consists in writing all customizations once, and just use \"assertThat (actual, Is(expected));\" for all tests;
     see the \"Organizing tests\" section.
     
     Under the hood:
     - `assertThat()` get an optionnal user message, the value to match (of type `Object?`), and a `Matcher`, that will check the value;
     - `Is` examines its argument (the expected value) and delegates matching to another matcher, depending on the value type. 
        For String is uses `EqualsMatcher`, which uses '==';
     - `assertThat()` calls the matcher `match(Object? actual)` method, that match the actual value against the `Is()` argument, 
       and return an `MatcherResult`. `MatcherResult` simply wraps a matched/not matched boolean, and a `Description` of what happened.
       `Description` is tree of objects describing the match, that can be translated later to various formats (short/long messages, text/html, etc).  
     - if matching failed, `assertThat()` delegates failure management to a `ResultHandler` implementation; by default it's a `ThrowingResultHandler`;
     - `ThrowingResultHandler` throws a `MatchException`, which carries the match `Description`, and `Description` translated to a short message, 
       as exception cause;
     - when `MatchException` is caught by the framework, it prints short message. Note that a suitable framework could also convert the `MatchException`
        `Description` field to other formats: multiline message, or HTML, more convenient for complex objects (eg lists, maps, etc).     
        
     
     # Matchers
     
     The `Matcher` implementations match actual object against specific values:  
     
         shared interface Matcher {
            shared formal Description description(Matcher (Object? ) resolver);
            shared formal MatcherResult match(Object? actual, 
                Matcher (Object? ) resolver = defaultMatcherResolver());
         }
     
     - `description()` is a short matcher description (typically less than one line). It is used inside other descriptions, for example 
     when a matcher depends on other matchers (eg [[AnyMatcher]]);
     
     - `match(Object? actual, Matcher (Object? ) resolver)` does the real job; the resulting `MatcherResult` 
        is a matched/mismatched boolean, plus a description of what happened.  
     
     Both methods have a `Matcher (Object? ) resolver` argument; it can be used if the matcher delegates its job to another matcher
     (eg [[Is]]); See the Resolver chapter for more. 
     
     The `Description` field of the `MatcherResult` returned by `match()`may be typically:
     - a `MatchDescription`, for simple values (eg integers or strings);
     - some `CompoundDescription`, for complex objects (lists, maps, custom objects);
     - any kind of description, eg if actual object type is not the expected one.
     Note that a description must be provided even if matching succeeded, because matching success is a failure cause of `NotMatcher`... 
     
     Usual matchers are:
     - [[Is]], the swiss knife of matchers: it delegates matching to a suitable matcher, 
       depending on the expected object type (see [[DefaultMatcherResolver]] doc); 
     - [[EqualsMatcher]] (uses ==), [[IdentifiableMatcher]] (uses ===), [[NotNullMatcher]]; 
     - [[StringMatcher]] (uses ==); 
     - [[ListMatcher]], [[MapMatcher]] for (surprise) lists and maps; 
     - [[ObjectMatcher]], [[FieldAdapter]], for custom class matching (see later)
     - logical matchers: [[AllMatcher]] (all children matchers must match), [[AnyMatcher]] (any child matcher must match), 
       [[NotMatcher]] (child matcher must fail), [[AnythingMatcher]] (always matches)
     - [[DescribedAsMatcher]] (decorating, adds a description message to another matcher description)
     - [[TypeMatcher]] (match types, currently incomplete, as ceylon 0.5 reflection/metaprogramming is inexistent)
     
     ## Custom simple values matchers
     
     Sometime, for simple values, [[EqualMatcher]] is not enough; for example you might want to match Floats 
     within a certain margin of (rounding) error. The [[EqualsOpMatcher]] provides a simple solution for 'simple' values: it delegates
     matching to a custom `Description?(T, T)` equals-like function, that returns null when matched,
     and a mismatch description otherwise. 
     For example, let's write a matcher for `Float` that tolerates an error margin:
     
         class FloatMatcher(
               Float expected,
               Float relativeError, // margin of error
               Descriptor descriptor = DefaultDescriptor()
         
         ) extends EqualsOpMatcher<Float>(
               expected,
               // Inline comparison function
               function (Float expected, Float actual) {
                   // Compare with error margin
                   if( (expected * (1-relativeError) <= actual <= expected * (1+relativeError)) ||
                       (actual * (1-relativeError) <= expected <= actual * (1+relativeError))) {
                       return null;
                   } else {
                       // Error message
                       return StringDescription(\"== within \``relativeError*100\``% : \", highlighted);
                   }
               },
               //
               \"== within \``relativeError*100\``% \",
               descriptor){
         }

     Check it:
         import java.lang { Math {pi = \\iPI}}
         void customMatcherTest() {
            // check sum(1/n^2) = pi^2 / 6 
            Float actual = Range(1, 1000).fold(0.0,
                function (Float s, Integer n) => s + 1.0/(n*n));
            assertThat(actual, FloatMatcher((pi*pi)/6, 0.001));
         } 
              
     ## Custom class matchers
     
     Simple custom class matchers can be created using [[ObjectMatcher]] and [[FieldAdapter]]. `FieldAdapter` delegates 
     a single field matching to a field specific matcher; `ObjectMatcher` delegates custom class matching 
     to a list of FieldAdapter. For example:
     
         void customClassTest() {
            // Class under test
            class User(shared String name, shared Integer age) {}
            
            // Our custom matcher
            class UserMatcher(User user) extends ObjectMatcher<User>(user, {
                FieldAdapter<User>(\"name\", (User expected) => EqualsMatcher(expected.name), (User actual)=>actual.name),
                FieldAdapter<User>(\"age\", (User expected) => EqualsMatcher(expected.age), (User actual)=>actual.age)
            }) {}
                
            // The test
            assertThat(null, User(\"Ted\", 30), UserMatcher(User(\"John\", 20)));
         }
     
     When run you get a \" &lt;&lt;&lt;User&gt;&gt;&gt; {name: ('=='\"John\"/&lt;&lt;&lt;\"Ted\"&gt;&gt;&gt;), age: ('=='20/&lt;&lt;&lt;30&gt;&gt;&gt;)}\"
     message.
     
     # Resolvers
     
     When matching a complex object, finding a matcher for a sub-object may be challenging. For example, 
     when matching lists or maps, there should be a way to specify element matchers. Generics may help in simple cases,
     but not for lists of lists of custom objects containing maps of...
     
     Basically creating matchers (what we call 'resolution') is delegated to functions of signature `Matcher (Object? expected)` or `Matcher? (Object? expected)`. 
     They get some expected value, and return some suitable matcher. For example, if expected is a String, it would typically return a [[StringMatcher]] instance.
     
     The [[defaultMatcherResolver]] function creates a resolver that tries a list of delegate resolvers (for custom classes), and, if no matcher was found, 
     returns a predefined matcher. It has matchers for usual classes (iterables, maps, strings), and falls back to an '==' based matcher. 
     
     So let's see it in action with previous `User` custom object, by comparing lists of users: first define a custom resolver:
     
         void customResolverTest() {
            // Class under test
            class User(shared String name, shared Integer age) {}
            
            // Our custom matcher (the same)
            class UserMatcher(User user) extends ObjectMatcher<User>(user, {
                FieldAdapter<User>(\"name\", (User expected) => EqualsMatcher(expected.name), (User actual)=>actual.name),
                FieldAdapter<User>(\"age\", (User expected) => EqualsMatcher(expected.age), (User actual)=>actual.age)
            }) {}
            
            // Our custom resolver, returns null if expected if not a User
            Matcher? customMatcherResolver(Object? expected) {
                if(is User expected) {
                    return UserMatcher(expected);
                }
                return null;
            }
          
            // Our custom resolver, returns default matchers if expected if not a User
            value customResolver = defaultMatcherResolver({customMatcherResolver});
            
            // Fire!
            assertThat(     {User(\"Ted\", 30), User(\"John\", 20)}, 
                ListMatcher({User(\"Ted\", 30), User(\"John\", 21)}), customResolver);
         }
     
     Result:
     
            1 mismatched: {
              User {name: (\"Ted\"), age: (30)}, 
              <<<At position 1 >>>ObjectMatcher: <<<User>>> {name: (\"John\"), age: ('=='21/<<<20>>>)}
            }
          
     We can also use it for `Is()`; it's convenient to define a custom 'assertThat' that use `customResolver`:

         void myAssertThat(Object? actual, Matcher matcher, String? userMsg = null) =>
            assertThat(actual, matcher, customResolver, userMsg);
      
         myAssertThat({User(\"Ted\", 30)}, Is({User(\"John\", 20)}));
                                                        
     
     # Descriptors
     
     When generating description messages, you may need to customize the way classes are printed.
     If they have a suitable `string` property, everything is fine, but sometimes they don't 
     and you can' (or don't want) to add it. Then the solution is to create a custom [[Descriptor]].
     A `Descriptor` converts an object to a String:
     
         shared interface Descriptor {
            shared formal String describe(Object? obj, DescriptorEnv descriptorEnv);
         }
         // Ignore DescriptorEnv for the moment, we'll see it in the section on footnotes
         shared interface DescriptorEnv {
            shared formal FootNote newFootNote(Description description);
         }

     Usually, descriptor defaults to [[DefaultDescriptor]].
     
     For example suppose you need to match complex numbers: 
       
         void customDescriptorTest() {
            // Class under test
            class Complex(shared Float re, shared Float im) {
                // Simple matching: defaultMatcherResolver returns an EqualMatcher 
                //(which calls equals()) for unknown objects: 
                shared actual Boolean equals(Object that) { 
                    if(is Complex that) {
                        return re == that.re && im == that.im;
                    }
                    return false;
                }
            }
            // Custom descriptor: customize Complex objects, otherwise delegate to DefaultDescriptor 
            object descriptor satisfies Descriptor {
                value default = DefaultDescriptor();
                shared actual String describe(Object? obj, DescriptorEnv descriptorEnv) {
                    if(is Complex obj) {
                        return \"\" + obj.re.string + \" + \" + obj.im.string + \"i \";
                    }
                    return default.describe(obj, descriptorEnv);
                }
            }
            // Customize assertThat() 
            value resolver = (Object? expected) => defaultMatcherResolver({}, descriptor)(expected);
            void myAssertThat(Object? actual, Matcher matcher, String? userMsg = null) =>
                assertThat(actual, matcher, resolver, userMsg); 
        
            myAssertThat(Complex(1.0, 0.1), Is(Complex(1.0, 0.0)));
         }
     
     The assertion will print:
            '=='1.0 + 0.0i /<<<1.0 + 0.1i >>>
     
     ### Long descriptions: footnotes
     
     If an object is too complex (eg a tree), its description may be lengthy, and may lead to hardly readable message.
     Matcher4cl provides a footnote mechanism, in which long descriptions may be deferred to the end of mismatch description: 
     - a descriptor creates a `Description` for the long message (as long as needed, eg using [[TreeDescription]]s);
     - it creates a new [[FootNote]] by `DescriptorEnv.newFootNote(Description)`;
     - it returns a short message, embedding the footnote index.
     When the mismatch description is created, footnotes are collected by the `DescriptorEnv`, and are appended 
     to the output message (eg by the `ThrowingResultHandler`).
     
     Example: let's write a config file parser, that return some detailed error description if it fails:
     
         // Error tree
         class Error(shared String msg, shared {Error*} causes = {}) {}
     
         class AppConfig(shared String appParam/*application configuration here*/) {}
         
         AppConfig|Error parseConfigFile(/*file path omitted for brevity*/) {
            // Always fails, for the demo
            return Error(\"Can't open application\", {
                        Error(\"Error reading config file 'myapp.config'\", {
                            Error(\"Config parameter xyz not found.\"),
                            Error(\"Config parameter tuv: invalid syntax.\")
                        })}); 
         }
  
     Embedding all messages in the short messages would be cumberstone, so we choose to write only the first one in the mismatch description
     and dump the whole tree in a footnote. We first need to convert an `Error` to a Description; as Error is a basically a tree,
     we use [[TreeDescription]]s and [[StringDescription]]s, in a recursive function:
     
         // Convert an error tree to a TreeDescription.
         Description describeErrorTree(Error error) {
            Description d = StringDescription(normalStyle, error.msg);
            if(error.causes.empty) {
                return d;
            } else {
                [Description*] causeDescrs = error.causes.collect((Error err) => describeErrorTree(err));
                return TreeDescription(d, causeDescrs); 
            }
         }
    
     So now we can write our custom descriptor:
     
         object customDescriptor satisfies Descriptor {
            value default = DefaultDescriptor();
            shared actual String describe(Object? obj, DescriptorEnv descriptorEnv) {
                
                if(is Error obj) {
                    FootNote footNote = descriptorEnv.newFootNote(describeErrorTree(obj));
                    return \"Error: \`\`obj.msg\`\` (see [\`\`footNote.reference\`\`])\";
                }
                if(is AppConfig obj) {
                    return \"AppConfig[ \" + obj.appParam + \" ])\";
                }
                return default.describe(obj, descriptorEnv);
            }
         }

     And if we try an assertion:
         void testConfigFileWithFootnotes() {
            assertThat(parseConfigFile(), EqualsMatcher(AppConfig(\"param\"), customDescriptor));
         }
     
     We get a mismatch message with a footnote:
     
         `'=='AppConfig[ param ])/<<<Error: Can't open application (see [0])>>>
         Reference [0]:
         Can't open application
           Error reading config file 'myapp.config'
             Config parameter xyz not found.
             Config parameter tuv: invalid syntax.`
     
     ## Descriptors for custom objects fields
     
     Custom matchers may be nested, if custom objects are nested; then matchers will delegate object field matching 
     to other matchers, recursively. You may need custom descriptors for your custom classes. Then how can you provide 
     the custom descriptor to nested objects ?
     Well, most implementations of Matcher get a [[Descriptor]] in their constructor argument lists, which usually
     defaults to [[DefaultDescriptor]]; when they create matchers for objects fields or sub-objects, they simply
     pass them this Descriptor. So if the top-level matcher get a custom Decriptor, all the sub-objects will get it.  
     
     For example, suppose a User holding a list of Phone objects, with custom descriptors:
     
            // Class under test: User with several phones
            class Phone(shared String phoneNb) {}
            class User(shared String name, shared {Phone*} phones) {}
            
            object customDescriptor satisfies Descriptor {
                value default = DefaultDescriptor();
                shared actual String describe(Object? obj, DescriptorEnv descriptorEnv) {
                    if(is User obj) {
                        return \"User \" + obj.name + \", phones: \" + obj.phones.string;
                    }
                    if(is Phone obj) {
                        return \"Phone: \" + obj.phoneNb;
                    }
                    return default.describe(obj, descriptorEnv);
                }
            }

     You can write a custom User matcher that delegates phones matching to a [[ListMatcher]], which in turn delegates to a custom 
     Phone matcher (assuming a suitable custom resolver). [[ListMatcher]] constructor has a [[Descriptor]] as second argument; 
     if list sizes differ, it will describe extra elements using this descriptor. So the User matcher needs to have a [[Descriptor]]
     as constructor argument, and pass it to its phone list matcher:
     
         // UserMatcher passes the (custom) descriptor to the phones ListMatcher
         class UserMatcher(User user, Descriptor descriptor) extends ObjectMatcher<User>(user, {
            FieldAdapter<User>(\"name\", (User expected) => EqualsMatcher(expected.name), (User actual)=>actual.name),
            FieldAdapter<User>(\"phones\", (User expected) => ListMatcher(expected.phones, descriptor), (User actual)=>actual.phones)
         }) {}
         class PhoneMatcher(Phone phone) extends ObjectMatcher<Phone>(phone, {
            FieldAdapter<Phone>(\"nb\", (Phone expected) => EqualsMatcher(expected.phoneNb), (Phone actual)=>actual.phoneNb)
         }) {}
        
     
         Matcher? customResolver(Object? expected) {
            switch(expected)
            case(is User) {return UserMatcher(expected, customDescriptor);}
            case(is Phone) {return PhoneMatcher(expected);}
            else {return null;}
         }
         value resolver = defaultMatcherResolver({customResolver}, customDescriptor);
        
     Check it:
     
         assertThat(     {User(\"Ted\", {Phone(\"00000\")})}, 
            ListMatcher( {User(\"Ted\", {Phone(\"00000\"), Phone(\"00001\")})}, customDescriptor), resolver);

     Or simplify by customizing assertThat():
          
         void myAssertThat(Object? actual, Matcher matcher, String? userMsg = null) =>
            assertThat(actual, matcher, resolver, userMsg); 

         myAssertThat( {User(\"Ted\", {Phone(\"00000\")})}, 
                Is(    {User(\"Ted\", {Phone(\"00000\"), Phone(\"00001\")})}));

     
     The extra element is written as \"Phone: 00001\":
     
          1 mismatched: {
            <<<At position 0 >>>ObjectMatcher: <<<User>>> {
              name: (\"Ted\"), 
              phones: (Expected list is longer than actual: 2 expected, 1 actual:  {
                 Phone {nb: (\"00000\")}
                } 
                => ERR 1 expected not in actual list:  {
                  Phone: 00001
                })
            }
          }
     
     
     # Output formats
     
     Matching results is mainly a [[Description]]; it is a tree structure, reflecting (more or less) the matched objects, 
     and intended to be converted to human-readble messages. In simple cases they are simple classes 
     ([[MatchDescription]], [[ValueDescription]]), but as matched objects may be complex classes (lists, maps, custom objects,
     and their combinations), it often ends up with a more general tree (of [[CompoundDescription]] and its descendants).
     Complex objects may lead to hardly readable descriptions; therefore descriptions may be written on several lines, 
     with indentation, to reflect the object tree structure.
     
     Let's have a look into `Description`:
     
         shared interface Description {
            shared formal void appendTo(StringBuilder stringBuilder, TextFormat textFormat, Integer depth);
            shared formal Integer level;
         }

     - `level` is (approximatively) the distance from tree node to its deepest leaf. For low values (typ. 0), the description is written 
       on a single line; otherwise chidren nodes are printed on different lines. For example, a list of integers is printed on a single line: 
       integers usually map to [[ValueDescription]], and their level is always 0, as [[ValueDescription]] has no children;
     - `appendTo` writes the description to `stringBuilder`. It doesn't write directly, but instead calls `textFormat` methods, which takes care 
       of indentations and multiline management. `depth` is the distance of the description node from tree root; it determines 
       the number of indentations.
     
     So, to create the output message, create a suitable `TextFormat`, a `StringBuilder` and call `appendTo()`. The `TextFormat` declaration is:
     
         shared interface TextFormat {
            shared formal void writeText(StringBuilder stringBuilder, TextStyle textStyle, String text); 
            shared formal void writeNewLineIndent(StringBuilder stringBuilder, Integer indentCount); 
         }
 
     - `writeText()` must write `text` to `stringBuilder`. `style` defines if the text must be highlighted as an error 
       (eg enclosed in '\\*', or with a red background in HTML...).
     - `writeNewLineIndent` writes a carriage return (or equivalent) in stringBuilder, followed by `indentCount` indentations.
     
     By default, the `SimpleTextFormat` writes description as single or multiline text, depending on a constructor parameter.
     
     ## Example: HTML output.
     
     We first need a `TextFormat` specialized for HTML:
     - text: highlighted errors will be enclosed in a <span> with an \"error\" CSS style; '<', '>' and '&' will be escaped;
     - new line/indent will use `<br/>` and `&nbsp;` ;
     
     
             class HtmlTextFormat() satisfies TextFormat {
                
                shared actual void writeNewLineIndent(StringBuilder stringBuilder, Integer indentCount) {
                    stringBuilder.append(\"<br/>\");
                    stringBuilder.appendNewline();  // Optional, makes HTML easier to read
                    for(Integer i in 0:indentCount) {
                        stringBuilder.append(\"&nbsp;&nbsp;&nbsp;&nbsp;\");
                    }
                }
                
                value escapes = HashMap{'<' -> \"&lt;\", '>' -> \"&gt;\", '&' -> \"&amp;\"} ;
                shared void escape(StringBuilder stringBuilder, String text) {
                    for(Character c in text) {
                        if(exists t = escapes[c]) {
                            stringBuilder.append(t);
                        } else {
                            stringBuilder.appendCharacter(c);
                        }
                    }
                }
                
                shared actual void writeText(StringBuilder stringBuilder, TextStyle style, String text) {
                    if(errorStyleyle == style) {
                        stringBuilder.append(\"<span class=\\\"error\\\">\");
                        escape(stringBuilder, text);
                        stringBuilder.append(\"</span>\");
                    } else {
                        escape(stringBuilder, text);
                    }
                }
             }

     Now we need a method to convert a Description to a file:
     
         void writeHtmlFile(Path filePath, Description description) {
            
            if(is File loc = filePath.resource) {   // Remove existing file, is any
                loc.delete();
            }
                
            if(is Nil loc = filePath.resource) {
                File file = loc.createFile();
                Writer writer = file.writer();
                writer.write(\"<html><head>
                              <style type=\\\"text/css\\\">
                                    .error {background-color:#FF183e;}
                              </style>
                              </head><body>\");
                writer.write(\"<h1>Example report</h1>\");
                
                // Write description
                StringBuilder sb = StringBuilder();
                DescriptorEnv descriptorEnv = DefaultDescriptorEnv();
                value format = HtmlTextFormat();
                description.appendTo(sb, format, 0, descriptorEnv);
                
                // Write footnotes
                for(fn in descriptorEnv.footNotes()) {
                    format.writeNewLineIndent(sb, 0);
                    format.writeNewLineIndent(sb, 0);
                    format.writeText(sb, normalStyle, \"Reference [\``fn.reference\``]:\");
                    format.writeNewLineIndent(sb, 0);
                    fn.description.appendTo(sb, format, 0, descriptorEnv);
                }
     
                writer.write(sb.string);
                writer.write(\"</body></html>\");
                writer.close(null);
            }
         }
     
     And now we can use it for test output (in /tmp/testReport.html):
     
         void htmlExample() {
            try {
                assertThat(\"Demo\", [100, 11, [13, \"<Hello>\"]], Is([10, 11, [12, \"<World>\"]]));
                
            } catch (MatchException e){
                // Write `e.mismatchDescription` to /tmp/testReport.html
                String? tmpPath = process.propertyValue(\"java.io.tmpdir\");
                assert(is String tmpPath);
                writeHtmlFile(parsePath(tmpPath).childPath(\"testReport.html\"), e.mismatchDescription);
            }
         }
     
     # Organizing tests
     
     If you have many custom classes, with custom resolvers and matchers, you could organise them as follow.
     First create an object to hold all custom resilver/matchers:
     
         // Some custom class
         class MyClass(shared String text) {}
        
         // Customization repository
         object testTools {
            
            // Descriptor for all custom classes that requires it
            object descriptor satisfies Descriptor {
               value default = DefaultDescriptor();
               shared actual String describe(Object? obj, DescriptorEnv descriptorEnv) {
                   // Add descriptions for custom classes that needs one (usually not necessary)
                   if(is MyClass obj) {
                       return \"\";   // description of MyClass; create footnote(s) if needed
                   }
                   // Fallback to default descriptor for other objects
                   return default.describe(obj, descriptorEnv);
               }
            }
            
            // Resolver for custom classes
            Matcher? customMatcherResolver(Object? expected) {
               if(is MyClass expected) {
                   return ObjectMatcher<MyClass>(expected, {
                       // Add a FieldAdapter<MyClass> for each field here
                       FieldAdapter<MyClass>(\"text\", (MyClass expected) => EqualsMatcher(expected.text), (MyClass act) => act.text)
                   }) ;
               }
               return null;
            }
            
            // Our custom resolver, returns default matchers if expected if not a User
            shared Matcher(Object?) resolver = defaultMatcherResolver({customMatcherResolver}, descriptor);
         }    

     
     Map default [[assertThat]] to cutom assertThat:

         import org.matcher4cl.core { defaultAssertThat = assertThat, Is}
         
         shared void assertThat(Object? actual, Matcher matcher, String? userMessage= null)
            => defaultAssertThat(actual, matcher, testTools.resolver, userMessage); 
     
     Now you can use assertThat and Is for any objects, custom or not:
     
         void test() {
            assertThat(MyClass(\"a\") /*actual*/, Is(MyClass(\"a\")) /*expected*/);
            assertThat(42, Is(42));
            assertThat([MyClass(\"a\"), 42, \"Hello\"], Is([MyClass(\"a\"), 43, \"Hello\"]) );
         }
     
     "
by "Jean-Pierre Ragey"
license "Apache Software License V2.0" 
module org.matcher4cl.core '0.1.0' {
    import ceylon.test '0.6';
    import ceylon.collection '0.6';
}
