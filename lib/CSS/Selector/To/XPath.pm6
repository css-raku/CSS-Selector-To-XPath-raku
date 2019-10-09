use v6;

unit class CSS::Selector::To::XPath;

multi method xpath(Pair $_) {
    self."xpath-{.key}"( .value );
}

multi method xpath(Hash $_ where .elems == 1) {
    self.xpath(.pairs[0]);
}

multi method xpath-op('=')  { '=' }                              # child
multi method xpath-op('>')  { '' }                               # child
multi method xpath-op('~')  { 'following-sibling::' }            # sibling
multi method xpath-op('+')  { 'following-sibling::*[1]/self::' } # adajacent
multi method xpath-op($_) is default {
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
        default { warn "unhandled attribute operator: $_"; '' }
    }
}

multi method _attrib-expr(% ( :not($expr)! ) ) {
    'not(' ~ $._attrib-expr(|$expr) ~ ')';
}

multi method _attrib-expr(%name) {
    '@' ~ $.xpath(%name)
}

multi method _attrib-expr(|c) { die c.perl }

multi method xpath-attrib(List $_) {
    '[' ~ $._attrib-expr(|$_) ~ ']';
}

method xpath-class(Str:D $_) {
    qq<[contains(concat(' ', normalize-space(@class), ' '), ' $_ ')]>;
}

method xpath-id(Str $_) {
    qq<[@id='$_']>
}

method xpath-ident(Str $_) {
    $_;
}

method xpath-qname(% (:$element-name!, :$ns-prefix)) {
    $element-name;
}

multi method xpath-pseudo-class('first-child') {
    '[count(preceding-sibling::*) = 0]'
}

multi sub pseudo-func('lang', % (:$ident )) {
    qq<[@xml:lang='{$ident}' or starts-with(@xml:lang, '{$ident}-')]>
}
multi sub pseudo-func($_, |c) is default {
    warn "unimplemented pseudo-function: $_";
    '';
}

multi method xpath-pseudo-func( % (:$ident!, :$expr )) {
    pseudo-func($ident, |$expr);
}

method xpath-selectors(List $_) {
    my @sel = .map({ $.xpath-selector(.<selector>) });
    @sel == 1 ?? @sel.head !! @sel.map({"($_)"}).join('|');
}

method xpath-selector(@spec) {
    my @sel;
    while (@spec) {
        my $xpath-op = '/';
        with @spec.head<op> {
            @spec.shift;
            $xpath-op = $.xpath-op($_);
        }
        @sel.push: '/' ~ $xpath-op;
        @sel.push: $.xpath(@spec.shift);
    }
    @sel.join;
}

method xpath-simple-selector(List $_) {
    my $default-elem = .[0]<qname>.defined ?? '' !! '*';
    $default-elem ~ .map({ $.xpath($_) }).join;
}

method xpath-string(Str $_) {
    "'" ~ .subst("'", "''", :g) ~ "'";
}

method to-xpath(Str:D :$css-selectors) {
    my $actions = (require ::('CSS::Module::CSS3::Selectors::Actions')).new;
    if (require ::('CSS::Module::CSS3::Selectors')).parse($css-selectors, :rule<selectors>, :$actions) {
        $.xpath($/.ast);
    }
    else {
        fail "unable to pass CSS selector: $css-selectors";
    }
}


