import ceylon.test { createTestRunner, failure, TestListener, error, TestResult, TestDescription }


void run() {
    
    object printingTestListener satisfies TestListener {
        
        shared actual void testFinish(TestResult result) {
            
            print("Test finished: ``result.description``");
            
            void printTestDescription(TestDescription description, String indent="") {
                print("``indent`` ``description.name``");
                for(child in description.children) {
                    printTestDescription(child, indent+"  ");
                }
            }
            
            
            if(result.state == failure ||result.state == error) {
                print("Error: ");
                printTestDescription(result.description);
                if(exists e = result.exception) {
                    print("Exception: ``e.message``");
                    e.printStackTrace();
                }
            }
        }
        shared actual void testIgnored(TestResult result) {
            print("Test ignored: ``result.description``");
        }
        shared actual void testError(TestResult result) {
            print("Test error: ``result.description``");
            
        }
    }

    value result = createTestRunner{
        sources = [`module org.matcher4cl.test`];
        listeners = [printingTestListener];
    }.run();

    print("matcherResolverTestSuite result: ``result``");

}
