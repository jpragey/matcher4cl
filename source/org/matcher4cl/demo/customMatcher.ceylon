import org.matcher4cl.core{ Descriptor, DefaultDescriptor, EqualsOpMatcher, highlighted, assertThat, StringDescription }
import java.lang { Math {pi = \iPI}}

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
               return StringDescription("== within ``relativeError*100``% : ", highlighted);
           }
       },
       //
       "== within ``relativeError*100``% ",
       descriptor){}
   
void customMatcherTest() {
 
    // check sum(1/n^2) = pi^2 / 6 
    Float actual = Range(1, 1000).fold(0.0,
        function (Float s, Integer n) => s + 1.0/(n*n));
    assertThat(actual, FloatMatcher((pi*pi)/6, 0.001));
}