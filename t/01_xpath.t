use v6;
use CSS::Selector::To::XPath :selector-to-xpath;
use Test;

use JSON::Fast;

for '[1a]', '[-1a]', '[--a]', '[!a]', '[ab!c]', '[]', '[x=1a]', '[x=-1a]',
     '[x=--a]', '[x=!a]', '[x=ab!c]', '[x="]', '[x="abc" "]', '[x=abc z]' -> $css {
    dies-ok { selector-to-xpath(:$css) }, "invalid css selector: $css";
}

for 't/01_xpath.json'.IO.lines {
    next if .starts-with('//');
    my ($css, $xpath) = @( from-json($_) );
    if $css eq 'todo' {
        todo($xpath);
    }
    else {
        is selector-to-xpath(:$css), $xpath, "css to xpath: $css";
    }
}


done-testing();
