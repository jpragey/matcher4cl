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

Matcher4cl is a pure Ceylon library; it needs ceylon 0.6.

Installation
============
    git clone git://github.com/jpragey/matcher4cl.git
    # or 
    git clone https://github.com/jpragey/matcher4cl

    cd matcher4cl/
    ceylon compile org.matcher4cl.{core,demo,test}
    ceylon doc org.matcher4cl.{core,demo,test}

The doc is in modules/org/matcher4cl/core/0.1.0/module-doc/index.html
