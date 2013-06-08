import org.matcher4cl.core{ assertThat, Is }

void doTest() {
    assertThat ("The actual value", Is("The expected one"));
}

void doTestWithUserMsg() {
    assertThat {"Hello"; Is("World"); userMsg = "Some test";};
}
