import org.matcher4cl.core{ assertThat, DefaultMatcherResolver, Is, Descriptor, DefaultDescriptor }


void customDescriptorTest() {
    // Class under test
    class Complex(re, im) {
        shared Float re; 
        shared Float im;
        // Simple matching: DefaultMatcherResolver returns an EqualMatcher for unknown objects: 
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
        shared actual String describe(Object? obj) {
            if(is Complex obj) {
                return "" + obj.re.string + " + " + obj.im.string + "i ";
            }
            return default.describe(obj);
        }
    }
    
    class MyIs(Object? expected) extends Is (expected, DefaultMatcherResolver({}, descriptor)){}
    
    assertThat(Complex(1.0, 0.1), MyIs(Complex(1.0, 0.0)));
}


