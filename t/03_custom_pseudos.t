use v6;
use Test;
use CSS::Selector::To::XPath :%PSEUDO-CLASSES;
plan 5;

%PSEUDO-CLASSES<visited> = 'visited()';
my CSS::Selector::To::XPath $to-xml .= new;

is $to-xml.pseudo-classes<visited>, 'visited()', 'inherited pseudo-class';
$to-xml.pseudo-classes<hover> = 'hover()';
isnt %PSEUDO-CLASSES<hover>, 'hover()';

for (
    'a:visited' => '//a[visited()]',
    'a:hover'    => '//a[hover()]',
    'a:root'    => '//a[not(parent::*)]',
) {
    my Str $css = .key;
    my Str $expected = .value;
    my Str $xpath = $to-xml.selector-to-xpath(:$css);
    is($xpath, $expected, "css selection: $css")
    || do {
        diag "selector=$css";
        diag "xpath:$xpath";
    }
}

done-testing();
