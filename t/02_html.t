use v6;
use Test;
use CSS::Selector::To::XPath;
try require LibXML;
if $! {
    skip-rest("LibXML is required to run these tests");
    exit 0;
}

my $tests = ::('LibXML').load: :file<t/02_html.xml>;
my CSS::Selector::To::XPath $translator .= new: :prefix<.>;

for $tests<tests/test> {
    my Str $css = .<@selector>.Str;
    my Str $xpath = $translator.selector-to-xpath(:$css);
    my $in = .<in>[0];
    my $expected = .<expected>[0];
    is($in.findnodes($xpath).Str, $expected.nonBlankChildNodes.Str, "css selection: $css")
    || do {
        diag "selector=$css";
        diag "xpath:$xpath";
        diag "in:$in";
    }
}

done-testing;
