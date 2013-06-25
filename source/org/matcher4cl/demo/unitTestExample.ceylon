import org.matcher4cl.core{ assertThat, Is, ObjectMatcher, Matcher, defaultMatcherResolver, Descriptor, DefaultDescriptor, DescriptorEnv }


// -- Simplest test case
void doTest() {
    assertThat ("The actual value", Is("The expected one"));
}

void doTestWithUserMsg() {
    assertThat {"Hello"; Is("World"); userMsg = "Some test";};
}

// -- Custom object test case
shared class Country(shared String name, shared String capital) {}

void countryTest() {
    assertThat(       Country("USA", "New york"),
        ObjectMatcher(Country("USA", "New York"))
    );
}


void countryTest2() {
    // -- Infrastructure (typ. defined once in the project)
    // Converts objects to String - needed because Country has no suitable string property
    value customDescriptor = DefaultDescriptor(
        (Object? obj, DescriptorEnv descriptorEnv) {
            if(is Country obj) {
                return "Country(``obj.name``: ``obj.capital``)";
            }
            return null;
        }
    );
    
    // Get suitable Matcher for some expected object
    Matcher? customResolver(Object? expected) {
      if(is Country expected) {
          return ObjectMatcher<Country>{expected = expected;/* descriptor = customDescriptor;*/};
      }
      return null;
    }
    // Redefine assertThat() to use customResolver and customDescriptor
    void myAssertThat(Object? actual, Matcher matcher)
            => assertThat(actual, matcher, defaultMatcherResolver({customResolver}, customDescriptor)); 

    // -- The test itself
    // Actual object
    Map<String, {Country*}> act = LazyMap<String, {Country*}>{
        "Asia"    -> [Country("China", "Beijing")],
        "America" -> [Country("USA", "New york")],  // Notice 'york' with lower case 'y''
        "Europe"  -> [Country("England", "London"), Country("France", "Paris")]
    }; 
    
    // Match
    myAssertThat(act, Is(LazyMap<String, {Country*}>{
        "Asia"    -> [Country("China", "Beijing")],
        "America" -> [Country("USA", "New York")],
        "Europe"  -> [Country("England", "London"), Country("France", "Paris")]
    }));
                /*
1 values mismatched: {
  "Asia"->[Country(China: Beijing)], 
  "America"->Value mismatch for "ListMatcher": [Country(USA: New York)]/<<<[Country(USA: New york)]>>>
      Cause:
      1 mismatched: {
        <<<At position 0 >>>ObjectMatcher: <<<Country>>> {capital: ("New York"/<<<"New york">>>: expected[4]='Y'(89=#59) != actual[4]='y'(121=#79)), name: ("USA")}
      }, 
  "Europe"->[Country(England: London), Country(France: Paris)]
}                
                */
    // 1 values mismatched: {
    //   "Asia"->[org.matcher4cl.demo.Country@ca9890e]/[org.matcher4cl.demo.Country@4ca59c12], 
    //   "America"->Value mismatch for "ListMatcher": [org.matcher4cl.demo.Country@48059495]/<<<[org.matcher4cl.demo.Country@4e64fca0]>>>
    //       Cause:
    //       1 mismatched: {
    //         <<<At position 0 >>>ObjectMatcher: <<<Country>>> {capital: ("New York"/<<<"New york">>>: expected[4]='Y'(89=#59) != actual[4]='y'(121=#79)), name: ("USA")}
    //       }, 
    //   "Europe"->[org.matcher4cl.demo.Country@197d96f9, org.matcher4cl.demo.Country@442c282]/[org.matcher4cl.demo.Country@665de723, org.matcher4cl.demo.Country@1ef1df56]
    // }


}
void countryTest3() {

    value customDescriptor = DefaultDescriptor(
        (Object? obj, DescriptorEnv descriptorEnv) {
            if(is Country obj) {
                return "Country(``obj.name``: ``obj.capital``)";
            }
            return null;
        }
    );
    
    Matcher? customResolver(Object? expected) {
      if(is Country expected) {
          return ObjectMatcher<Country>{expected = expected; descriptor = customDescriptor;};
      }
      return null;
    }
    void customAssertThat(Object? actual, Matcher matcher)
            => assertThat(actual, matcher, defaultMatcherResolver({customResolver}, customDescriptor)); 
    
    Map<String, Country> continents = LazyMap<String, Country>{
        "America" -> Country("USA", "New york")
    }; 
    
    //customAssertThat([Country("USA", "New york"), Country("England", "London"), Country("France", "Paris")],
    //         Is(     [Country("USA", "New York"), Country("England", "London"), Country("France", "Paris")])
    //);
    customAssertThat(continents,
            Is(LazyMap<String, Country>{
                "America" -> Country("USA", "New York")
            })
    );
    //1 mismatched: {
    //  <<<At position 0 >>>ObjectMatcher: <<<Country>>> {capital: ("New York"/<<<"New york">>>: expected[4]='Y'(89=#59) != actual[4]='y'(121=#79)), name: ("USA")}, 
    //  Country {capital: ("London"), name: ("England")}, 
    //  Country {capital: ("Paris"), name: ("France")}
    //}

}
