[![Build Status](https://travis-ci.org/css-raku/CSS-Selector-To-XPath-raku.svg?branch=master)](https://travis-ci.org/css-raku/CSS-Selector-To-XPath-raku)

[[Raku CSS Project]](https://css-raku.github.io)
 / [[CSS-Selector-To-XPath]](https://css-raku.github.io/CSS-Selector-To-XPath-raku)

NAME
====

CSS::Selector::To::XPath - Raku CSS Selector to XPath compiler

SYNOPSIS
========

    use CSS::Selector::To::XPath;
    my $c2x = CSS::Selector::To::XPath.new;
    say $c2x.query-to-xpath('li#main');
    # //li[@id='main']

    # functional interface
    use CSS::Selector::To::XPath :selector-to-xpath;
    my $xpath = selector-to-xpath: :css<div.foo>;
    # //div[contains(concat(' ', @class, ' '), ' foo ')]

    my $relative = selector-to-xpath: :css<div.foo>, :relative;
    # ./div[contains(concat(' ', @class, ' '), ' foo ')]

    my $ns = selector-to-xpath: :css<div.foo>, :prefix<xhtml>;
    # //xhtml:div[contains(concat(' ', @class, ' '), ' foo ')]

DESCRIPTION
===========

CSS::Selector::To::XPath is a utility function to compile the full set of CSS2 and partial set CSS3 selectors to equivalent XPath expressions.

FUNCTIONS and METHODS
=====================

  * selector-to-xpath

        $xpath = selector-to-xpath(:$css, :$html, |%opt);

    Shortcut for `CSS::Selector::To::XPath.new(|%opt).to-xpath(:$css) `. Parses the CSS selector expression and returns an equivalent XPath expression. Exported upon request.

  * new

        $sel = CSS::Selector::To::XPath.new(:$prefix, :relative);

    Creates a new object.

  * xpath

        my $actions = CSS::Module::CSS3::Selectors::Actions.new: :xml;
        CSS::Module::CSS3::Selectors.parse('e[foo]', :rule<selectors>, :$actions;
        my $ast = $/.ast;
        say CSS::Selector::To::XPath.xpath($ast); # //e[@foo]

        $ast = :attrib[{:ident("foo")},];
        say CSS::Selector::To::XPath.xpath($ast); # @foo

    This is a more advanced method that bypasses parsing of CSS selector expressions. Instead it constructs XPath expressions directly from AST trees, as produced by the CSS::Module::CSS3::Selectors parser.

CUSTOM PSEUDO FUNCTIONS
=======================

This module has built-in support for only the following Pseudo Classes:

    :checked :disabled :empty :first-child :first-of-type :last-child :last-of-type :only-child :only-of-type :root :selected

In particular, the following dynamic pseudo classes DO NOT have a default definition:

    :link :visited :hover :active :focus

This is because they are UI independent and do not have a standard XPath function

Defining Custom Pseudo Classes
------------------------------

Additional pseudo classes mapping can be defined by adding them to the global `%PSEUDO-CLASSES` variable or to the `.pseudo-classes()` Hash accessor:

    use CSS::Selector::To::XPath :%PSEUDO-CLASSES;
    # set-up a global xpath mapping
    %PSEUDO-CLASSES<visited> = 'my-visited-func(.)';
    #-OR-
    # set-up a mapping on an object instance
    my CSS::Selector::To::XPath $to-xml .= new;
    $to-xml.pseudo-classes<visited> = 'my-visited-func(.)';

    say $to-xml.selector-to-xpath: :css('a:visited');
    # //a[my-visited-func(.)]

In the above example `my-visited-func()` needs to be implemented as a custom function in the XPath processor.

Fallback Pseudo Classes and Functions
-------------------------------------

This is an additional mechanism to set the `:fallback` option for both pseudo classes and functions. This will map all unknown pseudos to a fallback xpath function. The default arguments to the function are `(name, ., arg1, arg2, ...)` where `name` is the name of the pseudo (lowercase), `.` is the current node and `arg1, arg2, ...` are any arguments that have been passed to pseudo functions.

    use CSS::Selector::To::XPath;
    my CSS::Selector::To::XPath $to-xml .= new(:fallback<pseudo>);
    say $to-xml.selector-to-xpath: :css('a:visited:color("blue")');
    # /a[pseudo('visited', .)][pseudo('color', ., 'blue')]

The fallback function may need to be implemented as a custom function in the XPath processor.

Mini Tutorial on CSS Selectors
==============================

Expressions
-----------

Selectors can match elements using any of the following criteria:

  * `name` – Match an element based on its name (tag name). For example, p to match a paragraph. You can use `*` to match any element.

  * `#id` – Match an element based on its identifier (the id attribute). For example, `#page`.

  * `.class` – Match an element based on its class name, all class names if more than one specified.

  * `[attr]` – Match an element that has the specified attribute.

  * `[attr=value]` – Match an element that has the specified attribute and value. (More operators are supported see below)

  * `:pseudo-class` – Match an element based on a pseudo class, such as `:empty`.

  * `:pseudo-function(arg)` – Match an element based on a pseudo class, such as `:nth-child(2n+1)`.

  * `:not(expr)` – Match an element that does not match the negation expression.

When using a combination of the above, the element name comes first followed by identifier, class names, attributes, pseudo classes and negation in any order. Do not separate these parts with spaces! Space separation is used for descendant selectors.

For example:

`form.login[action=/login]`

The matched element must be of type form and have the class login. It may have other classes, but the class login is required to match. It must also have an attribute called action with the value /login.

This selector will match the following element:

`form class="login form" method="post" action="/login"`

but will not match the element:

`form method="post" action="/logout"`

Attribute Values
----------------

Several operators are supported for matching attributes:

  * `name` – The element must have an attribute with that name.

  * `name=value` – The element must have an attribute with that name and value.

  * `name^=value` – The attribute value must start with the specified value.

  * `name$=value` – The attribute value must end with the specified value.

  * `name*=value` – The attribute value must contain the specified value.

  * `name~=word` – The attribute value must contain the specified word (space separated).

  * `name|=word` – The attribute value must start with specified word.

For example, the following two selectors match the same element:

`#my_id` `[id=my_id]`

and so do the following two selectors:

`.my_class` `[class~=my_class]`

Alternatives, siblings, children
--------------------------------

Complex selectors use a combination of expressions to match elements:

  * `expr1 expr2` – Match any element against the second expression if it has some ancestor element that matches the first expression.

  * `expr1 > expr2` – Match any element against the second expression if it is the immediate child of an element that matches the first expression.

  * `expr1 + expr2` – Match any element against the second expression if it immediately follows an element that matches the first expression.

  * `expr1 ~ expr2` – Match any element against the second expression that comes after an element that matches the first expression.

  * `expr1, expr2` – Match any element against the first expression, or against the second expression.

Since children and sibling selectors may match more than one element given the first element, the #match method may return more than one match.

Pseudo classes Pseudo classes were introduced in CSS 3. They are most often used to select elements in a given position:
------------------------------------------------------------------------------------------------------------------------

  * `:root` – Match the element only if it is the root element (no parent element).

  * `:empty` – Match the element only if it has no child elements, and no text content.

  * `:only-child` – Match the element if it is the only child (element) of its parent element.

  * `:only-of-type` – Match the element if it is the only child (element) of its parent element and its type.

  * `:first-child` – Match the element if it is the first child (element) of its parent element.

  * `:first-of-type` – Match the element if it is the first child (element) of its parent element of its type.

  * `:last-child` – Match the element if it is the last child (element) of its parent element.

  * `:last-of-type` – Match the element if it is the last child (element) of its parent element of its type.

Pseudo functions
----------------

  * `:content(string)` – Match the element only if it has string as its text content (ignoring leading and trailing white-space).

  * `:nth-child(b)` – Match the element if it is the b-th child (element) of its parent element. The value `b` specifies its index, starting with 1.

  * `:nth-child(an+b)` – Match the element if it is the b-th child (element) in each group of a child elements of its parent element.

  * `:nth-child(-an+b)` – Match the element if it is the first child (element) in each group of a child elements, up to the first `b` child elements of its parent element.

  * `:nth-child(even)` – Match element in the even position (i.e. second, fourth). Same as `:nth-child(2n)`.

  * `:nth-child(odd)` – Match element in the odd position (i.e. first, third). Same as `:nth-child(2n+1)`.

  * `:nth-of-type(..)` – As above, but only counts elements of its type.

  * `:nth-last-child(..)` – As above, but counts from the last child.

  * `:nth-last-of-type(..)` – As above, but counts from the last child and only elements of its type.

  * `:not(selector)` – Match the element only if the element does not match the simple selector.

For example:

`table tr:nth-child(odd)` Selects every second row in the table starting with the first one.

`div p:nth-child(4)` Selects the fourth paragraph in the div, but not if the div contains other elements, since those are also counted.

`div p:nth-of-type(4)` Selects the fourth paragraph in the div, counting only paragraphs, and ignoring all other elements.

`div p:nth-of-type(-n+4)` Selects the first four paragraphs, ignoring all others.

And you can always select an element that matches one set of rules but not another using `:not`. For example:

`p:not(.post)` Matches all paragraphs that do not have the class `.post`.

ACKNOWLEDGEMENTS
================

This Raku module is based on tests from the Perl HTML::Selector::XPath module. Some rules have been derived from the notogiri Ruby gem.

Material for the 'Mini Tutorial on CSS Selectors' has been adapted from https://www.rubydoc.info/docs/rails/4.1.7/HTML/Selector.

LICENSE
=======

This library is free software; you can redistribute it and/or modify it under the same terms as Rakudo itself.

