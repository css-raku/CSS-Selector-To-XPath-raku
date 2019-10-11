use v6;
use CSS::Selector::To::XPath;
use Test;

use JSON::Fast;

for 't/01_xpath.json'.IO.lines {
    next if .starts-with('//');
    my ($css-selector, $xpath) = @( from-json($_) );
    if $css-selector eq 'todo' {
        todo($xpath);
    }
    else {
        is CSS::Selector::To::XPath.to-xpath($css-selector), $xpath, $css-selector;
    }
}


done-testing();
