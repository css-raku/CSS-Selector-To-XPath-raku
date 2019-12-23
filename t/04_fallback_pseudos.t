use v6;
use Test;
use CSS::Selector::To::XPath;
plan 5;

my CSS::Selector::To::XPath $to-xml .= new(:fallback<pseudo>);

is $to-xml.fallback, 'pseudo', ':fallback option';

for (
    'a:visited' => "//a[pseudo('visited', .)]",
    'a:Hover'   => "//a[pseudo('hover', .)]",
    'a:Color("blue")'   => "//a[pseudo('color', ., 'blue')]",
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
