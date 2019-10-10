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
        when '$=' { qq<substring($att, string-length($att)-{$v.chars-1})=$.xpath-string($v)> }
        when '|=' { qq<$att=$.xpath-string($v) or starts-with($att, $.xpath-string($v~'-'))> }
        when '*=' { qq<contains($att, $.xpath-string($v))> }
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

method xpath-qname(% (:$element-name!, :$ns-prefix)) {
    $element-name;
}

multi method xpath-pseudo-class('first-child') {
    'count(preceding-sibling::*) = 0'
}

multi method xpath-pseudo-class('last-child') {
    'count(following-sibling::*) = 0'
}

multi method xpath-pseudo-class($_) is default {
    fail "unimplemented pseudo-class: $_";
}

multi method _pseudo-func('lang', % (:$ident )) {
    qq<@xml:lang='{$ident}' or starts-with(@xml:lang, '{$ident}-')>
}

multi method _pseudo-func('contains', %val) {
    my $s = %val<ident> // %val<string>;
    qq<text()[contains(string(.), {$.xpath-string($s)})]>;
}

sub grok-AnB-expr(@expr) {
    # parse an expression of the form: An+B (or 'odd' or 'even')
    my $A = 0;
    my $B = 0;
    my $v;
    my $sign = 1;

    for @expr -> $tk {
        for $tk.values {
            when Int:D  { $v = $sign * $_; $sign = 1 }
            when 'odd'  { $A = 2; $B = 1 }
            when 'even' { $A = 2; $B = 0 }
            when '+'    { $sign = +1 }
            when '-'    { $sign = -1 }
            when 'n'    { $A = $v // 1; $v = Mu }
            default { warn "ignoring '$_' token in AnB expression"; }
        }
    }
    $B = $_ with $v;
    $A, $B;
}

sub write-AnB($A, $B is copy) {
    $B += $A if $B < 0;
    my $V = $A ~~ 0|1 ?? '' !! ' mod ' ~ $A;
    "$V = $B";
}

multi method _pseudo-func('nth-child', *@expr) {
    my ($a, $b) = grok-AnB-expr(@expr);
    'count(preceding-sibling::*)' ~ write-AnB($a, $b-1);
}

multi method _pseudo-func('nth-of-type', *@expr) {
    my ($a, $b) = grok-AnB-expr(@expr);
    $a ?? 'position()' ~ write-AnB($a, $b) !! $b;
}

multi method _pseudo-func('not', $expr) {
    qq<not({$.xpath($expr)})>;
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
    my @l = .list;
    my $elem = do with @l.head<qname> {
        $.xpath(@l.shift);
    }
    else {
        '*';
    }
    $elem ~ @l.map({ '[' ~ $.xpath($_) ~ ']' }).join;
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


