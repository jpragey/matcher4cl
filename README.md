Matcher4cl
==========

- [Status](#status)
- [Licence](#licence)
- [Installation](#installation)
- [10 mn introduction](#10-mn-introduction)
- [More](#more)


Matcher4cl is a matcher library for the Ceylon programming language.

Unit testing involves matching calculated values against expected ones; matcher4cl simplifies matching 'complex' values:
 - provides relevant human-readable messages (tree presentation, footnotes);
 - provides default matchers for lists and maps;
 - integrates easily with ceylon test.

Flexibility is a fundamental goal of matcher4cl:
 - create matchers for custom classes;
 - create non-standard matchers for existing classes (eg Float with allowed rounding error);
 - customize output formats. ASCII is provided out of the box, but other formats (like HTML) can be easily written.

Matcher4cl needs ceylon 0.6 (currently in github). 

Status
======

Matcher4cl is still in an 'everything can (but only if necessary) change' status.
I expect to stabilize it roughly when Ceylon 1.0 is out.

Licence
=======
   Apache 2.0:  http://www.apache.org/licenses/LICENSE-2.0.html

Installation
============
  You need a jdk 1.7, git, Ceylon 0.6 and optionnaly ant.

    git clone git://github.com/jpragey/matcher4cl.git
    # or 
    git clone https://github.com/jpragey/matcher4cl

    cd matcher4cl/
    # With ant: 
    ant clean doc publish
    
    # Without ant: 
    ceylon compile org.matcher4cl.{core,demo,test}
    ceylon doc org.matcher4cl.{core,demo,test}
    mkdir -p ~/.ceylon/repo/org/matcher4cl
    cp -R ./modules/org/matcher4cl/core ~/.ceylon/repo/org/matcher4cl/
    

The doc is in modules/org/matcher4cl/core/0.1.0/module-doc/index.html

10 mn introduction
==================
A matcher is an object that checks that another object is 'equal' to a predefined value. 
Its most common usage is probably testing, when the actual result of an expression must match an expected value,
otherwise an exception is thrown, carrying some meaningfull mismatch description.
So let's go:
```ceylon
 import org.matcher4cl.core { assertThat, Is }
 void doTest() {
    assertThat ("The actual value", Is("The expected one"));
 }
```
And add the import to your module.ceylon:
```ceylon
 import org.matcher4cl.core "0.1.0";
```
Run it as a usual ceylon application, and you'll get  an exception stating:
```
 "The expected one"/<<<"The actual value">>>: expected[4]='e'(101=#65) != actual[4]='a'(97=#61)
```

The "<<< >>>" is ASCII art for highlighting; the string matcher describe the first mismatching character, convenient 
for differentiating non conventional chars (eg space (#20) and non-breaking space (#A0)).  

To use it with custom classes:
```ceylon
 shared class Country(shared String name, shared String capital) {}

 void countryTest() {
    assertThat(       Country("USA", "New york"),   // Lower case 'y'
        ObjectMatcher(Country("USA", "New York"))
    );
 }
```
The result is:
```
 <<<Country>>> {capital: ("New York"/<<<"New york">>>: expected[4]='Y'(89=#59) != actual[4]='y'(121=#79)), name: ("USA")}
```
  
What if you need to compare more complex structures (eg maps of lists containing custom objects)? Well, you need a bit of infrastructure:

```ceylon
 import org.matcher4cl.core { defaultAssertThat = assertThat,  // Because we'll redefine assertThat() 
 ... }

 // Our custom classes
 shared class City(shared String name) {}
 shared class Country(shared String name, shared String capital, shared {City *} cities={}) {}

 // -- Infrastructure: a Descriptor converts custom objects to strings, for displaying purpose only.
 // Not needed for custom classes that have a suitable \`string\` property.
 object descriptor extends DefaultDescriptor(
     (Object? obj, DescriptorEnv descriptorEnv) {
        if(is City obj) {
            return "City(``obj.name``)";
        }
        if(is Country obj) {
            return "Country(``obj.name``: ``obj.capital``)";
        }
        return null;
     }
 ){}

 // Resolver method: define how classes must be matched.
 // defaultResolver() will look first for matchers in its first argument; if not found,
 // it return some default matcher (suitable for Integer, String, Map, Iterable,etc). 
 Matcher (Object?) resolver = defaultResolver(
    (Object? expected){
        if(is City expected) {
            return ObjectMatcher<City>(
                expected,   // Expected City object 
                {},         // No explicit FieldAdapter: ObjectMatcher looks for for shared properties by metamodel
                            // and create one using this resolver.
                            // So for the 'String name' property, a StringMatcher will be created.  
                descriptor);
        }
        if(is Country expected) {
            return ObjectMatcher<Country>(
                expected,   // Expected Country object.
                {},         // No explicit FieldAdapter: ObjectMatcher looks for for shared properties by metamodel
                            // and create one using this resolver.
                            // So for the '{City *} cities' property, a ListMatcher will be created 
                            //  ('defaultResolver()' default for iterators); then this ListMatcher will create a Matcher 
                            //  for each City in the same way (using this 'defaultResolver()'); that is, 
                            // ListMatcher will create the ObjectMatcher<City> we've just defined.
                descriptor);
        }
       return null;
    }
	, descriptor);
     
 // Now we redefine 'assertThat' to use our custom resolver:
 void assertThat(Object? actual, Matcher matcher)
     => defaultAssertThat(actual, matcher, resolver); 
```

Now the tests themselves:
```ceylon
 void countryTest() {

 // -- The test itself
 assertThat(
     // Actual object
     LazyMap<String, {Country*}>{
         "Asia"    -> [Country("China", "Beijing")],
         "America" -> [Country("USA", "New York", {City("Waschington")})],  // Note: 'sch' in 'Waschington' 
         "Europe"  -> [Country("England", "London"), 
                       Country("France", "Paris", {City("Lyon")})] //Note: unexpected {City("Lyon")} 
     }, 
     // Expected object
     Is(LazyMap<String, {Country*}>{
         "Asia"    -> [Country("China", "Beijing")],
         "America" -> [Country("USA", "New York", {City("Washington")})],
        "Europe"  -> [Country("England", "London"), 
                       Country("France", "Paris")]
     }));

 }
```

In Eclipse, you can run it as aCeylon application, or a usual Ceylon test, if the ceylon test plugin is installed (dont't forget to add
  import ceylon.test "0.6";
to module.ceylon).

The message depicts the objects structure, with emphasis on what went wrong:

```
 2 values mismatched: {
      "Asia"->[Country(China: Beijing)], 
      "America"->Value mismatch for "ListMatcher": [Country(USA: New York)]/<<<[Country(USA: New York)]>>>
          Cause:
          1 mismatched: {
            <<<At position 0 >>>ObjectMatcher: <<<org.matcher4cl.mytest.Country>>> {
              name: ("USA"), 
              capital: ("New York"), 
              cities: (1 mismatched: {
                  <<<At position 0 >>>ObjectMatcher: <<<org.matcher4cl.mytest.City>>> {
                    name: ("Washington"/<<<"Waschington">>> Sizes: actual=11 != expected=10
                        : expected[3]='h'(104=#68) != actual[3]='c'(99=#63))
                  }
                })
            }
          }, 
      "Europe"->Value mismatch for "ListMatcher": [Country(England: London), Country(France: Paris)]/<<<[Country(England: London), Country(France: Paris)]>>>
          Cause:
          1 mismatched: {
            org.matcher4cl.mytest.Country {
              name: ("England"), 
              capital: ("London"), 
              cities: ({})
            }, 
            <<<At position 1 >>>ObjectMatcher: <<<org.matcher4cl.mytest.Country>>> {
              name: ("France"), 
              capital: ("Paris"), 
              cities: (Actual list is longer than expected: 0 expected, 1 actual:  {}
                 => ERR 1 actual not in expected list:  {City(Lyon)})
            }
          }
    }
```


The basic usage pattern consists in writing all customizations once, and just use "assertThat (actual, Is(expected));" for all tests;
see the "Organizing tests" section.

Under the hood:
- `assertThat` get the value to match (of type `Object?`), a `Matcher` (`Is` here), that will check the value, and an optionnal user message;
- `Is` examines its argument (the expected value) and delegates matching to another matcher, depending on the value type. 
For String is uses `StringMatcher`, which uses '==';
- `assertThat()` calls the matcher `match(Object? actual, Matcher(Object?) resolver)` method, that match the actual value against the `Is()` argument, 
and return an `MatcherResult`. `MatcherResult` simply wraps a matched/not matched boolean, and a `Description` of what happened.
`Description` is tree of objects describing the match, that can be translated later to various formats (short/long messages, text/html, etc).  
- if matching failed, `assertThat()` delegates failure management to a `ResultHandler` implementation; by default it's a `ThrowingResultHandler`;
- `ThrowingResultHandler` throws a `MatchException`, which carries the match `Description`, and `Description` translated to a short message, 
as exception cause;
- when `MatchException` is caught by the framework, it prints a multiline text message. Note that a suitable framework could also convert the `MatchException`
`Description` field to other formats: short message, HTML, etc.     


# More

Much more doc can be found in generated doc, in 
```
  <matcher4cl>/modules/org/matcher4cl/core/0.1.0/module-doc/index.html
```  
