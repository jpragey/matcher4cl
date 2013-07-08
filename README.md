Matcher4cl
==========

- [Status](#status)
- [Licence](#licence)
- [Installation](#installation)
- [10 mn introduction](#10-mn-introduction)

Matcher4cl is a matcher library for the Ceylon programming language.

Unit testing involves matching calculated values against expected ones; matcher4cl simplifies matching 'complex' values:
 - provides easy-to-read messages;
 - provides default matchers for lists and maps;
 - integrates easily with ceylon test.

Flexibility is a fundamental goal of matcher4cl:
 - create matchers for custom classes;
 - create non-standard matchers for existing classes (eg Float with allowed rounding error);
 - customize output formats. ASCII is provided out of the box, but other formats (like HTML) can be easily written.

Matcher4cl needs ceylon 0.6 (currently in github). 

Status
======

Matcher4cl is still in an 'everything can (if necessary) change' status, like Ceylon itself:

 - Ceylon has a few features under developpment (metaprogramming, annotations) that may impact Matcher4cl;
 - Matcher4cl is young.
  
I expect to stabilize it roughly when Ceylon 1.0 is out.

Licence
=======
   Apache 2.0:  http://www.apache.org/licenses/LICENSE-2.0.html

Installation
============
  You need a jdk 1.7, git, a recent Ceylon (from GitHub : http://ceylon-lang.org/code/contribute/) and optionnaly ant.

    git clone git://github.com/jpragey/matcher4cl.git
    # or 
    git clone https://github.com/jpragey/matcher4cl

    cd matcher4cl/
    # With ant: 
    ant clean compile test doc
    
    # Without ant: 
    ceylon compile org.matcher4cl.{core,demo,test}
    ceylon doc org.matcher4cl.{core,demo,test}

The doc is in modules/org/matcher4cl/core/0.1.0/module-doc/index.html


# 10 mn introduction

A matcher is an object that checks that another object is 'equal' to a predefined value. 
Its most common usage is probably testing, when the actual result of an expression must match an expected value,
otherwise an exception is thrown, carrying some meaningfull mismatch description.
So let's go:
```ceylon
import org.matcher4cl.core { assertThat, Is }
void doTest() {
   assertThat (\"The actual value\", Is(\"The expected one\"));
}
```    
Run it as a usual ceylon application, and you'll get  an exception stating:
>    \"The expected one\"/<<<\"The actual value\">>>: expected[4]='e'(101=#65) != actual[4]='a'(97=#61)

The \"&lt;&lt;&lt; &gt;&gt;&gt;\" is ASCII art for highlighting; the string matcher describe the first mismatching character, convenient 
for differentiating non conventional chars (eg space (#20) and non-breaking space (#A0)).  
 
To use it with custom classes:
```ceylon
shared class Country(shared String name, shared String capital) {}

void countryTest() {
   assertThat(       Country(\"USA\", \"New york\"),   // Lower case 'y'
       ObjectMatcher(Country(\"USA\", \"New York\"))
   );
}
```    
The result is:
>    <<&lt;Country&gt;>> {capital: (\"New York\"/<<<\"New york\">>>: expected[4]='Y'(89=#59) != actual[4]='y'(121=#79)), name: (\"USA\")}

What if you need to compare more complex structures (eg maps of lists containing custom objects)? Well, you need a bit of infrastructure:

```ceylon
import org.matcher4cl.core { defaultAssertThat = assertThat } // Because we'll redefine assertThat()

// Our custom class
shared class Country(shared String name, shared String capital) {}

// -- Infrastructure (typically defined once in the project)
// Converts objects to String - needed because Country has no suitable \`string\` property
object descriptor extends DefaultDescriptor(
   (Object? obj, DescriptorEnv descriptorEnv) {
       if(is Country obj) {
           return \"Country(\`\`obj.name\`\`: \`\`obj.capital\`\`)\";
       }
       return null;
   }
){}

// Helps getting the right matcher for objects embedded in lists, maps, etc
Matcher (Object?) resolver = defaultResolver(
   (Object? expected){
       if(is Country expected) {
           return ObjectMatcher<Country>{expected = expected; descriptor = descriptor;};
       }
       return null;
   }
, descriptor);

// Redefine assertThat to use our custom resolver
void assertThat(Object? actual, Matcher matcher)
       => defaultAssertThat(actual, matcher, resolver); 
```    
   
Now the tests themselves:
   
```ceylon
void countryTest3() {
   
   // -- The test itself
   assertThat(
       // Actual object
       LazyMap<String, {Country*}>{
           \"Asia\"    -> [Country(\"China\", \"Beijing\")],
           \"America\" -> [Country(\"USA\", \"New york\")],  // Notice 'york' with lower case 'y''
           \"Europe\"  -> [Country(\"England\", \"London\"), Country(\"France\", \"Paris\")]
       }, 
       // Expected object
       Is(LazyMap<String, {Country*}>{
           \"Asia\"    -> [Country(\"China\", \"Beijing\")],
           \"America\" -> [Country(\"USA\", \"New York\")],
           \"Europe\"  -> [Country(\"England\", \"London\"), Country(\"France\", \"Paris\")]
       }));

}
```
The message depicts the objects structure, with emphasis on what went wrong:
```
    1 values mismatched: {
      \"Asia\"->[Country(China: Beijing)], 
      \"America\"->Value mismatch for \"ListMatcher\": [Country(USA: New York)]/<<<[Country(USA: New york)]>>>
          Cause:
          1 mismatched: {
            <<<At position 0 >>>ObjectMatcher: <<<Country>>> {capital: (\"New York\"/<<<\"New york\">>>: expected[4]='Y'(89=#59) != actual[4]='y'(121=#79)), name: (\"USA\")}
          }, 
      \"Europe\"->[Country(England: London), Country(France: Paris)]
    }     
```

In Eclipse, you can run it as a usual Ceylon test, if the ceylon test plugin is installed.

The basic usage pattern consists in writing all customizations once, and just use \"assertThat (actual, Is(expected));\" for all tests.

For more docs, see in modules/org/matcher4cl/core/0.1.0/module-doc/index.html



