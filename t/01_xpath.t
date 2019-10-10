use v6;
use CSS::Selector::To::XPath;
use Test;

use JSON::Fast;

for 't/01_xpath.json'.IO.lines {
    next if .starts-with('//');
    my ($css-selectors, $xpath) = @( from-json($_) );
    if $css-selectors eq 'todo' {
        todo($xpath);
    }
    else {
        is CSS::Selector::To::XPath.to-xpath(:$css-selectors), $xpath, $css-selectors;
    }
}


done-testing();
