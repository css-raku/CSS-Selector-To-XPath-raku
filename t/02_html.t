use v6;
use Test;
use CSS::Selector::To::XPath;
try require LibXML;
if $! {
    skip-rest("LibXML is required to run these tests");
    exit 0;
}

my $tests = ::('LibXML').load: :file<t/02_html.xml>;
my CSS::Selector::To::XPath $from-css .= new: :prefix<.>;

for $tests<tests/test> {
    my Str $css-selector = .<@selector>.Str;
    my Str $xpath = $from-css.to-xpath($css-selector);
    my $in = .<in>[0];
    my $expected = .<expected>[0];
    is($in.findnodes($xpath).Str, $expected.nonBlankChildNodes.Str, $css-selector)
    || do {
        diag "selector=$css-selector";
        diag "xpath:$xpath";
        diag "in:$in";
    }
}

done-testing;
