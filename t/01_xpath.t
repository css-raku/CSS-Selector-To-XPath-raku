use v6;
use CSS::Selector::To::XPath :selector-to-xpath;
use Test;

use XML;
use XML::Entity;

for '[1a]', '[-1a]', '[--a]', '[!a]', '[ab!c]', '[]', '[x=1a]', '[x=-1a]',
     '[x=--a]', '[x=!a]', '[x=ab!c]', '[x="]', '[x="abc" "]', '[x=abc z]' -> $css {
    dies-ok { selector-to-xpath(:$css) }, "invalid css selector: $css";
}

my XML::Document $tests = from-xml-stream("t/01_xpath.xml".IO.open(:r));
for $tests.elements {
    my $css   = decode-xml-entities(.<css>);
    my $xpath = decode-xml-entities(.<xpath>);
    if $css eq 'todo' {
        todo($xpath);
    }
    else {
        is selector-to-xpath(:$css), $xpath, "css to xpath: $css";
    }
}


done-testing();
