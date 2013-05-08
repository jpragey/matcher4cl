matcher4cl
==========

Matcher library for Ceylon.

Unit testing involves matching calculated values against expected ones; matcher4cl simplifies matching 'complex' values:
 - provides easy-to-read messages;
 - provides default matchers for lists and maps;
 - integrates easily with ceylon test.

Flexibility is a fundamental goal of matcher4cl:
 - create matchers for custom classes;
 - create non-standard matchers for existing classes (eg Float with allowed rounding error);
 - customize output formats. ASCII is provided out of the box, but other formats (like HTML) can be easily written.

Matcher4cl is a pure Ceylon library.
