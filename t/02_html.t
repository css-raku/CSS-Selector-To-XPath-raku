use v6;
use Test;
use CSS::Selector::To::XPath;
try require LibXML:ver(v0.2.0+);

if $! {
    plan 1;
    skip-rest("LibXML is required to run these tests");
    exit 0;
}

my $tests = ::('LibXML').load: :file<t/02_html.xml>;
my CSS::Selector::To::XPath $translator .= new: :relative;
ok $translator.relative, 'translator is relative';

for $tests<tests/test> {
    my Str $css = .attribute('selector').Str;
    my $in = .first('in');
    my $expected = .first('expected');
    my Str $xpath = $translator.selector-to-xpath(:$css, :html);
    is($in.findnodes($xpath).Str, $expected.elements.Str, "css selection: $css")
    || do {
        diag "selector=$css";
        diag "xpath:$xpath";
        diag "in:$in";
    }
}

done-testing;
