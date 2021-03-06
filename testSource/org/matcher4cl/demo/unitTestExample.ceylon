import org.matcher4cl.core{ assertThat, Is, ObjectMatcher, Matcher, defaultResolver, Descriptor, DefaultDescriptor, DescriptorEnv }


// -- Simplest test case
void doTest() {
    assertThat ("The actual value", Is("The expected one"));
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
            => assertThat(actual, matcher, defaultResolver(customResolver, customDescriptor)); 

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
}

void countryTest3() {
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
    
    Matcher (Object?) resolver = defaultResolver(
        (Object? expected){
            if(is Country expected) {
                return ObjectMatcher<Country>{expected = expected; descriptor = customDescriptor;};
            }
            return null;
        }
    , customDescriptor);
    
    void customAssertThat(Object? actual, Matcher matcher)
            => assertThat(actual, matcher, resolver); 
    
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
