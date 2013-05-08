import org.matcher4cl.core{ assertThat, Is }

void doTest() {
    assertThat("Hello", Is("World"), "Some test");
}
