import org.matcher4cl.core{ assertThat, Is, ObjectMatcher, Matcher, defaultMatcherResolver }


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
    
    Matcher? customResolver(Object? expected) {
      if(is Country expected) {
          return ObjectMatcher<Country>(expected) ;
      }
      return null;
    }
    void customAssertThat(Object? actual, Matcher matcher)
            => assertThat(actual, matcher, defaultMatcherResolver({customResolver})); 
    
    Map<String, {Country*}> continents = LazyMap<String, {Country*}>{
        "America" -> [Country("USA", "New york")],
        "Europe"  -> [Country("England", "London"), Country("France", "Paris")]
    }; 
    
    //customAssertThat([Country("USA", "New york"), Country("England", "London"), Country("France", "Paris")],
    //         Is(     [Country("USA", "New York"), Country("England", "London"), Country("France", "Paris")])
    //);
    customAssertThat(continents,
             Is(LazyMap<String, {Country*}>{
                    "America" -> [Country("USA", "New York")],
                    "Europe"  -> [Country("England", "London"), Country("France", "Paris")]
                })
    );
    //1 mismatched: {
    //  <<<At position 0 >>>ObjectMatcher: <<<Country>>> {capital: ("New York"/<<<"New york">>>: expected[4]='Y'(89=#59) != actual[4]='y'(121=#79)), name: ("USA")}, 
    //  Country {capital: ("London"), name: ("England")}, 
    //  Country {capital: ("Paris"), name: ("France")}
    //}

}
