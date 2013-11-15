import ceylon.test { createTestRunner, failure, TestListener, error, TestResult, TestDescription, TestRunResult }


void runTests() {
    
    object printingTestListener satisfies TestListener {
        shared SequenceBuilder<TestDescription> testDescrBuilder = SequenceBuilder<TestDescription>();
        
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
                testDescrBuilder.append(result.description);
            }
        }
        shared actual void testIgnored(TestResult result) {
            print(" ** Test ignored: ``result.description``");
        }
        shared actual void testError(TestResult result) {
            print(" ** Test error: ``result.description``");
            
        }
    }

    TestRunResult result = createTestRunner{
        sources = [`module org.matcher4cl.core`];
        listeners = [printingTestListener];
    }.run();

    print("matcherResolverTestSuite result: ``result``");
    if(result.isSuccess) {
        print(" ** All test passed.");
    } else {
        TestDescription[] failedTests = printingTestListener.testDescrBuilder.sequence; 
        print(" ** Failed: ``failedTests.size`` tests failed:");
        for(td in failedTests) {
            print("   ``td.name``");
        }
        
        throw Exception("Failed: ``failedTests.size`` tests failed.");
    }

}
