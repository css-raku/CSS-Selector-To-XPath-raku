use v6;
use CSS::Selector::To::XPath;
use Test;

for (
    '*' => '//*',
    'e' => '//e',
    'e f' => '//e//f',
    'e > f' => '//e/f',
    'e, f' => '(//e)|(//f)',
    'e ~ f' => '//e/following-sibling::f',
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
) {
    is CSS::Selector::To::XPath.to-xpath(:css-selectors(.key)), .value, .key;
}


done-testing();
