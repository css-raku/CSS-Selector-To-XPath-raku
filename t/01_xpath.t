use v6;
use CSS::Selector::To::XPath;
use Test;

my $todo;

for (
    '*' => '//*',
    'e' => '//e',
    'e f' => '//e//f',
    'e > f' => '//e/f',
    'e, f' => '//e | //f',
    'p.pastoral.marine' => q<//p[contains(concat(' ', normalize-space(@class), ' '), ' pastoral ')][contains(concat(' ', normalize-space(@class), ' '), ' marine ')]>,
    'e:first-child' => '//e[count(preceding-sibling::*) = 0]',
    'f > e:first-child' => '//f/e[count(preceding-sibling::*) = 0]',
    'e:lang(en)' => q<//e[@xml:lang='en' or starts-with(@xml:lang, 'en-')]>,
    'e + f' => '//e/following-sibling::*[1]/self::f',
    'e + #bar' => q<//e/following-sibling::*[1]/self::*[@id='bar']>,
    'e + .bar' => q<//e/following-sibling::*[1]/self::*[contains(concat(' ', normalize-space(@class), ' '), ' bar ')]>,
    'e[foo]' => '//e[@foo]',
    'e[foo=warning]' => q<//e[@foo='warning']>,
    'e[foo="warning"]' => q<//e[@foo='warning']>,
    'e[foo~="warning"]' => q<//e[contains(concat(' ', @foo, ' '), ' warning ')]>,
    'e[foo^="warning"]' => q<//e[starts-with(@foo, 'warning')]>,
    'e:not([foo^="warning"])' => q<//e[not(starts-with(@foo, 'warning'))]>,
    q<e[foo$="warning"]> => q<//e[substring(@foo, string-length(@foo)-6)='warning']>,
    q<E[lang|="en"]> => q<//e[@lang='en' or starts-with(@lang, 'en-')]>,
    'DIV.warning' => q<//div[contains(concat(' ', normalize-space(@class), ' '), ' warning ')]>,
    'E#myid' => q<//e[@id='myid']>,
    'todo' => 'check this',
    'p:not(#me)' => q<//p[not(@id='me')]>,
    'foo.bar, bar' => q<//foo[contains(concat(' ', normalize-space(@class), ' '), ' bar ')] | //bar>,
    'E:nth-child(1)' => '//e[count(preceding-sibling::*) = 0]',
    'E:last-child' => '//e[count(following-sibling::*) = 0]',
    'F E:last-child' => '//f//e[count(following-sibling::*) = 0]',
    'F > E:last-child' => '//f/e[count(following-sibling::*) = 0]',
    q<E[href*="bar"]> => q<//e[contains(@href, 'bar')]>,
    q<E[href*=bar]> => q<//e[contains(@href, 'bar')]>,
    q<E:not([href*="bar"])> => q<//e[not(contains(@href, 'bar'))]>,
    'F > E:nth-of-type(3)' => '//f/e[3]',

    'E:nth-child(odd)' => '//e[count(preceding-sibling::*) mod 2 = 0]',
    'E:nth-child(2n+1)' => '//e[count(preceding-sibling::*) mod 2 = 0]',

    'E:nth-child(even)' => '//e[count(preceding-sibling::*) mod 2 = 1]',
    'E:nth-child(2n)'   => '//e[count(preceding-sibling::*) mod 2 = 1]',

    'e ~ f' => '//e/following-sibling::f',
    'e ~ f.foo' => q<//e/following-sibling::f[contains(concat(' ', normalize-space(@class), ' '), ' foo ')]>,
    'E:contains("Hello")' => q<//e[text()[contains(string(.), 'Hello')]]>,
    q<E:contains( "Hello" ) .C> => q<//e[text()[contains(string(.), 'Hello')]]//*[contains(concat(' ', normalize-space(@class), ' '), ' C ')]>,
    q<F, E:contains( "Hello" )> => q<//f | //e[text()[contains(string(.), 'Hello')]]>,
    q<E:contains( "Hello" ), F> => q<//e[text()[contains(string(.), 'Hello')]] | //f>,
    q<E ~ #bar> => q<//e/following-sibling::*[@id='bar']>,
    q<E ~ .bar> => q<//e/following-sibling::*[contains(concat(' ', normalize-space(@class), ' '), ' bar ')]>,
    q<E ~ *> => q<//e/following-sibling::*>,
    q<.foo ~ E> => q<//*[contains(concat(' ', normalize-space(@class), ' '), ' foo ')]/following-sibling::e>,
    q<.foo ~ *> => q<//*[contains(concat(' ', normalize-space(@class), ' '), ' foo ')]/following-sibling::*>,
    q<.foo ~ .bar> => q<//*[contains(concat(' ', normalize-space(@class), ' '), ' foo ')]/following-sibling::*[contains(concat(' ', normalize-space(@class), ' '), ' bar ')]>,
    todo => 'is this a valid selector?',
    '> em' => q<//*/em>,
    q<:first-child> => q<//*[count(preceding-sibling::*) = 0]>,
    q<:last-child> => q<//*[count(following-sibling::*) = 0]>,
) {
    if .key eq '' && .value eq '' {
    }
    elsif .key eq 'todo' {
        todo(.value);
    }
    else {
        is CSS::Selector::To::XPath.to-xpath(:css-selectors(.key)), .value, .key;
    }
}


done-testing();
