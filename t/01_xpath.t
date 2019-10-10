use v6;
use CSS::Selector::To::XPath;
use Test;

my $todo;


my %seen;

for (
    '*' => '//*',
    'e' => '//e',
    'e f' => '//e//f',
    'e > f' => '//e/f',
    'e, f' => '//e | //f',
    'p.pastoral.marine' => q<//p[contains(concat(' ', normalize-space(@class), ' '), ' pastoral ')][contains(concat(' ', normalize-space(@class), ' '), ' marine ')]>,
    'e:first-child' => '//e[count(preceding-sibling::*) = 0 and parent::*]',
    'f > e:first-child' => '//f/e[count(preceding-sibling::*) = 0 and parent::*]',
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
    'E:nth-child(1)' => '//e[count(preceding-sibling::*) = 0 and parent::*]',
    'E:last-child' => '//e[count(following-sibling::*) = 0 and parent::*]',
    'F E:last-child' => '//f//e[count(following-sibling::*) = 0 and parent::*]',
    'F > E:last-child' => '//f/e[count(following-sibling::*) = 0 and parent::*]',
    q<E[href*="bar"]> => q<//e[contains(@href, 'bar')]>,
    q<E[href*=bar]> => q<//e[contains(@href, 'bar')]>,
    q<E:not([href*="bar"])> => q<//e[not(contains(@href, 'bar'))]>,
    'F > E:nth-of-type(3)' => '//f/e[3]',

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
    q<:first-child> => q<//*[count(preceding-sibling::*) = 0 and parent::*]>,
    q<:last-child> => q<//*[count(following-sibling::*) = 0 and parent::*]>,
    q<E.c:first-child> => q<//e[contains(concat(' ', normalize-space(@class), ' '), ' c ')][count(preceding-sibling::*) = 0 and parent::*]>,
    q<E:first-child.c> => q<//e[count(preceding-sibling::*) = 0 and parent::*][contains(concat(' ', normalize-space(@class), ' '), ' c ')]>,
    q<E#i:first-child> => q<//e[@id='i'][count(preceding-sibling::*) = 0 and parent::*]>,
    q<E:first-child#i> => q<//e[count(preceding-sibling::*) = 0 and parent::*][@id='i']>,
    q<:lang(c)> => q<//*[@xml:lang='c' or starts-with(@xml:lang, 'c-')]>,
    q<:lang(c)#i> => q<//*[@xml:lang='c' or starts-with(@xml:lang, 'c-')][@id='i']>,
    q<#i:lang(c)> => q<//*[@id='i'][@xml:lang='c' or starts-with(@xml:lang, 'c-')]>,
    q<E:lang(c)#i> => q<//e[@xml:lang='c' or starts-with(@xml:lang, 'c-')][@id='i']>,
    q<E#i:lang(c)> => q<//e[@id='i'][@xml:lang='c' or starts-with(@xml:lang, 'c-')]>,
    q<*:lang(c)#i:first-child> => q<//*[@xml:lang='c' or starts-with(@xml:lang, 'c-')][@id='i'][count(preceding-sibling::*) = 0 and parent::*]>,
    q<E:lang(c):first-child#i> => q<//e[@xml:lang='c' or starts-with(@xml:lang, 'c-')][count(preceding-sibling::*) = 0 and parent::*][@id='i']>,
    q<E#i:lang(c):first-child> => q<//e[@id='i'][@xml:lang='c' or starts-with(@xml:lang, 'c-')][count(preceding-sibling::*) = 0 and parent::*]>,
    q<#bar> => q<//*[@id='bar']>,
    q<*[foo]> => q<//*[@foo]>,
    q<[foo]> => q<//*[@foo]>,
    q<.warning> => q<//*[contains(concat(' ', normalize-space(@class), ' '), ' warning ')]>,
    q<:nth-child(1)> => q<//*[count(preceding-sibling::*) = 0 and parent::*]>,
    q<E:nth-child(2)> => q<//e[count(preceding-sibling::*) = 1 and parent::*]>,
    q<E:nth-child(even)> => q<//e[count(preceding-sibling::*) mod 2 = 1 and parent::*]>,
    q<E:nth-child(2n)> => q<//e[count(preceding-sibling::*) mod 2 = 1 and parent::*]>,
    q<E:nth-child(2n+1)> => q<//e[count(preceding-sibling::*) mod 2 = 0 and parent::*]>,
    q<E:nth-child(odd)> => q<//e[count(preceding-sibling::*) mod 2 = 0 and parent::*]>,
    q<:root> => q</*>,
    q<E:root> => q</e>,
    q<E:empty> => q<//e[not(* or text())]>,
    q<:empty> => q<//*[not(* or text())]>,
    q<p , :root> => q<//p | /*>,
    q<p , q> => q<//p | //q>,
    q<div *:not(p) em> => q<//div//*[not(p)]//em>,
    q<a:not(.external)[href]> => q<//a[not(contains(concat(' ', normalize-space(@class), ' '), ' external '))][@href]>,
    q<div em:only-child> => q<//div//em[count(preceding-sibling::*) = 0 and count(following-sibling::*) = 0 and parent::*]>,
    q<[x=abc]> => q<//*[@x='abc']>,
    q<[x=a-bc]> => q<//*[@x='a-bc']>,
    q<[x=abc-]> => q<//*[@x='abc-']>,
    q<[x=ab--c]> => q<//*[@x='ab--c']>,
    q<option:not([value=""])> => q<//option[not(@value='')]>,
    q<option[ value="" ]> => q<//option[@value='']>,
    q<tr:not([class="wantedClass"])> => q<//tr[not(@class='wantedClass')]>,
    q<form[name='foo']> => q<//form[@name='foo']>,
    q<E:last-of-type> => q<//e[last()]>,
    q<E:disabled> => q<//e[@disabled]>,
    q<E:selected> => q<//e[@selected]>,
    q<E:checked> => q<//e[@checked]>,
) {
    if .key eq '' && .value eq '' {
    }
    elsif .key eq 'todo' {
        todo(.value);
    }
    else {
        die "seen {.key}" if %seen{.key}++;
        is CSS::Selector::To::XPath.to-xpath(:css-selectors(.key)), .value, .key;
    }
}


done-testing();
