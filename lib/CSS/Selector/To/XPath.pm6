use v6;

unit class CSS::Selector::To::XPath;

use CSS::Module::CSS3::Selectors;
subset NCName of Str is export(:NCName) where Str:U|/^<CSS::Module::CSS3::Selectors::element-name>$/;
subset QName of Str is export(:QName) where Str:U|/^<CSS::Module::CSS3::Selectors::qname>$/;
has Bool $.relative;
has NCName $.prefix;

multi method xpath(Pair $_) {
    self."xpath-{.key}"( .value );
}

multi method xpath(Hash $_ where .elems == 1) {
    self.xpath(.pairs[0]);
}

multi method xpath-combinator('>')  { '' }                               # child
multi method xpath-combinator('~')  { 'following-sibling::' }            # sibling
multi method xpath-combinator('+')  { 'following-sibling::*[1]/self::' } # adjacent
multi method xpath-combinator($_) is default {
    warn "ignoring CSS '$_' operator";
    '';
}

multi method _attrib-expr(%name, % ( :$op! ), %val) {
    my $att = '@' ~ $.xpath(%name);
    my $v = %val<ident> // %val<string>;
    with $op {
        when '='  { $att ~ '=' ~ $.xpath-string($v)  }
        when '^=' { qq<starts-with($att, $.xpath-string($v))> }
        when '~=' { qq<contains(concat(' ', $att, ' '), { $.xpath-string(' ' ~ $v ~ ' ') })> }
        when '$=' { qq<substring($att, string-length($att)-{$v.chars-1})=$.xpath-string($v)> }
        when '|=' { qq<$att=$.xpath-string($v) or starts-with($att, $.xpath-string($v~'-'))> }
        when '*=' { qq<contains($att, $.xpath-string($v))> }
        default { warn "unhandled attribute operator: $_"; '' }
    }
}

multi method _attrib-expr(%name) {
    '@' ~ $.xpath(%name)
}

multi method xpath-attrib(List $_) {
    $._attrib-expr(|$_);
}

method xpath-class(Str:D $_) {
    qq<contains(concat(' ', normalize-space(@class), ' '), ' $_ ')>;
}

method xpath-id(Str $_) {
    qq<@id={$.xpath-string($_)}>
}

method xpath-ident(Str $_) {
    $_;
}

method xpath-int(Int $_) {
    .Str;
}

method xpath-qname(% (:$element-name!, :$ns-prefix = $!prefix)) {
    with $ns-prefix {
        $_ ~ ':' ~ $element-name;
    }
    else {
        $element-name;
    }
}

multi method xpath-pseudo-class('checked') {
    '@checked';
}

multi method xpath-pseudo-class('disabled') {
    '@disabled';
}

multi method xpath-pseudo-class('empty') {
    'not(node())';
}

multi method xpath-pseudo-class('first-child') {
    'count(preceding-sibling::*) = 0 and parent::*'
}

multi method xpath-pseudo-class('first-of-type') {
    '1';
}

multi method xpath-pseudo-class('last-child') {
    'count(following-sibling::*) = 0 and parent::*'
}

multi method xpath-pseudo-class('last-of-type') {
    'last()';
}

multi method xpath-pseudo-class('only-child') {
    'count(preceding-sibling::*) = 0 and count(following-sibling::*) = 0 and parent::*'
}

multi method xpath-pseudo-class('only-of-type') {
    'count() = 1';
}

multi method xpath-pseudo-class('root') {
    'not(parent::*)'
}

multi method xpath-pseudo-class('selected') {
    '@selected';
}

multi method xpath-pseudo-class($_) is default {
    die "unimplemented pseudo-class: $_";
}

multi method _pseudo-func('lang', % (:$ident )) {
    qq<lang(., {$ident})>;
}

multi method _pseudo-func('contains', %val) {
    my $s = %val<ident> // %val<string>;
    qq<text()[contains(., {$.xpath-string($s)})]>;
}

sub grok-AnB-expr(@expr) {
    # parse an expression of the form: An+B (or 'odd' or 'even')
    my $A = 0;
    my $B = 0;
    my $v;
    my $sign = 1;

    for @expr -> $tk {
        for $tk.values {
            when Int:D  { $v = $_  }
            when 'odd'  { $A = 2; $B = 1 }
            when 'even' { $A = 2; $B = 0 }
            when '+'    { }
            when '-'    { $sign *= -1 }
            when 'n'    {
                $A = ($v // 1)  * $sign;
                $v = Nil;
                $sign = 1;
            }
            default { warn "ignoring '$_' token in AnB expression"; }
        }
    }
    $B = ($_ * $sign) with $v;
    $A, $B;
}

sub write-AnB($n, Int $A is copy, Int $B is copy) {
    $A ||= 0;
    if $A > 0 {
        $B += $A while $B < 0;
    }

    when $A == 0  { "$n = $B" }
    when $A == 1  { "$n > $B" }
    when $A >  1  {
        given "$n mod $A = $B" {
            $B > 1 ?? "$_ and $n >= $B" !! $_;
        }
    }
    when $A == -1 { "$n <= $B" }
    when $A <  -1 { "$n * {-$A} <= $B" }
}

multi method _pseudo-func('nth-child', *@expr) {
    my ($a, $b) = grok-AnB-expr(@expr);
     write-AnB('count(preceding-sibling::*)', $a, $b-1) ~ ' and parent::*';
}

multi method _pseudo-func('nth-last-child', *@expr) {
    my ($a, $b) = grok-AnB-expr(@expr);
    write-AnB('count(following-sibling::*)', $a, $b-1) ~ ' and parent::*';
}

multi method _pseudo-func('nth-of-type', *@expr) {
    my ($a, $b) = grok-AnB-expr(@expr);
    $a ?? write-AnB('position()', $a, $b) !! $b;
}

multi method _pseudo-func('nth-last-of-type', *@expr) {
    my ($a, $b) = grok-AnB-expr(@expr);
    $a ?? write-AnB('count() - position()', $a, $b-1) !! 'count() - ' ~ ($b - 1);
}

multi method _pseudo-func('not', $expr) {
    my $axes = $expr<qname> ?? 'self::' !! '';
    qq<not({$axes}{$.xpath($expr)})>;
}
multi method _pseudo-func($_, *@expr) is default {
    warn "unimplemented pseudo-function: $_\({@expr.perl}\)";
    '';
}

multi method xpath-pseudo-func( % (:$ident!, :$expr )) {
    $._pseudo-func($ident, |$expr);
}

method xpath-selectors(List $_) {
    my @sel = .map({ $.xpath-selector(.<selector>) });
    @sel == 1 ?? @sel.head !! @sel.join(' | ');
}

method xpath-selector(@spec) {
    my @sel;
    @sel.push('.') if $!relative;
    while (@spec) {
        my $combinator = '/';
        with @spec.head<op> {
            @spec.shift;
            $combinator = $.xpath-combinator($_);
        }
        my $xpath = $.xpath(@spec.shift);
        @sel.push: '/';
        @sel.push: $combinator;
        @sel.push: $xpath;
    }
    @sel.join;
}

method xpath-simple-selector(List $_) {
    my @l = .list;

    my $elem = do with @l.head<qname> {
        $.xpath(@l.shift);
    }
    else {
        '*';
    }

    my @selections = @l.map: { '[' ~ $.xpath($_) ~ ']' };
   $elem ~ @selections.join;
}

method xpath-string(Str $_) {
    "'" ~ .subst("'", "''", :g) ~ "'";
}

method selector-to-xpath($class = $?CLASS: Str:D :$css!, |c) is export(:selector-to-xpath) {
    my $obj = $class;
    $_ .= new(|c) without $obj;
    my $actions = (require ::('CSS::Module::CSS3::Selectors::Actions')).new: :xml;
    if CSS::Module::CSS3::Selectors.parse($css, :rule<selectors>, :$actions) {
        $obj.xpath($/.ast);
    }
    else {
        fail "unable to parse CSS selector: $css";
    }
}

=begin pod

=head1 NAME

CSS::Selector::To::XPath - Raku CSS Selector to XPath compiler

=head1 SYNOPSIS

  use CSS::Selector::To::XPath;
  given CSS::Selector::To::XPath.new {
      say .selector-to-xpath(:css<li#main">); # //li[@id='main']
  }

  # functional interface
  use CSS::Selector::To::XPath :selector-to-xpath;
  my $xpath = selector-to-xpath('div.foo');

  my $relative = selector-to-xpath('div.foo', :relative );
  # ./div[contains(concat(' ', @class, ' '), ' foo ')]

  my $ns = selector-to-xpath('div.foo', :prefix<xhtml> );
  # xhtml:div[contains(concat(' ', @class, ' '), ' foo ')]

=head1 DESCRIPTION

CSS::Selector::To::XPath is a utility function to compile full set of
CSS2 and partial CSS3 selectors to the equivalent XPath expression.

=head1 FUNCTIONS and METHODS

=begin item
selector-to-xpath

  $xpath = selector-to-xpath(:$css, |%opt);

Shortcut for C<< CSS::Selector::To::XPath.new(|%opt).to-xpath(:$css) >>. Exported upon request.
=end item

=begin item
new

  $sel = CSS::Selector::To::XPath.new(:$prefix, :relative);

Creates a new object.
=end item

=head1 Mini Tutorial on CSS Selectors

=head2 Expressions

Selectors can match elements using any of the following criteria:

=item C<name> – Match an element based on its name (tag name). For example, p to match a paragraph. You can use C<*> to match any element.

=item C<#id> – Match an element based on its identifier (the id attribute). For example, C<#page>.

=item C<.class> – Match an element based on its class name, all class names if more than one specified.

=item C<[attr]> – Match an element that has the specified attribute.

=item C<[attr=value]> – Match an element that has the specified attribute and value. (More operators are supported see below)

=item C<:pseudo-class> – Match an element based on a pseudo class, such as C<:empty>.

=item C<:pseudo-function(arg)> – Match an element based on a pseudo class, such as C<:nth-child(2n+1)>.

=item C<:not(expr)> – Match an element that does not match the negation expression.

When using a combination of the above, the element name comes first followed by identifier, class names, attributes, pseudo classes and negation in any order. Do not separate these parts with spaces! Space separation is used for descendant selectors.

For example:

C<form.login[action=/login]>

The matched element must be of type form and have the class login. It may have other classes, but the class login is required to match. It must also have an attribute called action with the value /login.

This selector will match the following element:

C<<form class="login form" method="post" action="/login">>

but will not match the element:

C<<form method="post" action="/logout">>

=head2 Attribute Values

Several operators are supported for matching attributes:

=item C<name> – The element must have an attribute with that name.

=item C<name=value> – The element must have an attribute with that name and value.

=item C<name^=value> – The attribute value must start with the specified value.

=item C<name$=value> – The attribute value must end with the specified value.

=item C<name*=value> – The attribute value must contain the specified value.

=item C<name~=word> – The attribute value must contain the specified word (space separated).

=item C<name|=word> – The attribute value must start with specified word.

For example, the following two selectors match the same element:

C<#my_id>
C<[id=my_id]>

and so do the following two selectors:

C<.my_class>
C<[class~=my_class]>
 
=head2 Alternatives, siblings, children

Complex selectors use a combination of expressions to match elements:

=item C<expr1 expr2> – Match any element against the second expression if it has some ancestor element that matches the first expression.

=item C«expr1 > expr2» – Match any element against the second expression if it is the immediate child of an element that matches the first expression.

=item C<expr1 + expr2> – Match any element against the second expression if it immediately follows an element that matches the first expression.

=item C<expr1 ~ expr2> – Match any element against the second expression that comes after an element that matches the first expression.

=item C<expr1, expr2> – Match any element against the first expression, or against the second expression.

Since children and sibling selectors may match more than one element given the first element, the #match method may return more than one match.

=head2 Pseudo classes
Pseudo classes were introduced in CSS 3. They are most often used to select elements in a given position:

=item C<:root> – Match the element only if it is the root element (no parent element).

=item C<:empty> – Match the element only if it has no child elements, and no text content.

=item C<:only-child> – Match the element if it is the only child (element) of its parent element.

=item C<:only-of-type> – Match the element if it is the only child (element) of its parent element and its type.

=item C<:first-child> – Match the element if it is the first child (element) of its parent element.

=item C<:first-of-type> – Match the element if it is the first child (element) of its parent element of its type.

=item C<:last-child> – Match the element if it is the last child (element) of its parent element.

=item C<:last-of-type> – Match the element if it is the last child (element) of its parent element of its type.

=head2 Pseudo functions

=item C<:content(string)> – Match the element only if it has string as its text content (ignoring leading and trailing whitespace).

=item C<:nth-child(b)> – Match the element if it is the b-th child (element) of its parent element. The value C<b> specifies its index, starting with 1.

=item C<:nth-child(an+b)> – Match the element if it is the b-th child (element) in each group of a child elements of its parent element.

=item C<:nth-child(-an+b)> – Match the element if it is the first child (element) in each group of a child elements, up to the first C<b> child elements of its parent element.

=item C<:nth-child(even)> – Match element in the even position (i.e. second, fourth). Same as C<:nth-child(2n)>.

=item C<:nth-child(odd)> – Match element in the odd position (i.e. first, third). Same as C<:nth-child(2n+1)>.

=item C<:nth-of-type(..)> – As above, but only counts elements of its type.

=item C<:nth-last-child(..)> – As above, but counts from the last child.

=item C<:nth-last-of-type(..)> – As above, but counts from the last child and only elements of its type.

=item C<:not(selector)> – Match the element only if the element does not match the simple selector.

For example:

C<table tr:nth-child(odd)>
Selects every second row in the table starting with the first one.

C<div p:nth-child(4)>
Selects the fourth paragraph in the div, but not if the div contains other elements, since those are also counted.

C<div p:nth-of-type(4)>
Selects the fourth paragraph in the div, counting only paragraphs, and ignoring all other elements.

C<div p:nth-of-type(-n+4)>
Selects the first four paragraphs, ignoring all others.

And you can always select an element that matches one set of rules but not another using C<:not>. For example:

C<p:not(.post)>
Matches all paragraphs that do not have the class C<.post>.

=head1 ACKNOWLEDGEMENTS

This Raku module is based on tests from the Perl 5 HTML::Selector::XPath module. Some rules have been
derived from the notogiri Ruby gem.

Material for the 'Mini Tutorial on CSS Selectors' has been adapted from https://www.rubydoc.info/docs/rails/4.1.7/HTML/Selector.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Rakudo itself.

=end pod
 
