use v6;

unit class CSS::Selector::To::XPath;

has Str $.prefix = '';

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

multi method xpath-pseudo-class('checked') {
    '@checked';
}

multi method xpath-pseudo-class('disabled') {
    '@disabled';
}

multi method xpath-pseudo-class('empty') {
    'not(* or text())';
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

multi method xpath-pseudo-class('root') {
    $*IS-ROOT = True;
    Mu;
}

multi method xpath-pseudo-class('selected') {
    '@selected';
}

multi method xpath-pseudo-class($_) is default {
    die "unimplemented pseudo-class: $_";
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
    'count(preceding-sibling::*)' ~ write-AnB($a, $b-1) ~ ' and parent::*';
}

multi method _pseudo-func('nth-last-child', *@expr) {
    my ($a, $b) = grok-AnB-expr(@expr);
    'count(following-sibling::*)' ~ write-AnB($a, $b-1) ~ ' and parent::*';
}

multi method _pseudo-func('nth-of-type', *@expr) {
    my ($a, $b) = grok-AnB-expr(@expr);
    $a ?? 'position()' ~ write-AnB($a, $b) !! $b;
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
    while (@spec) {
        my $*IS-ROOT = False;
        my $combinator = '/';
        with @spec.head<op> {
            @spec.shift;
            $combinator = $.xpath-combinator($_);
        }
        my $xpath = $.xpath(@spec.shift);
        @sel.push: '/'
            unless $*IS-ROOT;
        @sel.push: $combinator;
        @sel.push: $xpath;
    }
    $!prefix ~ @sel.join;
}

method xpath-simple-selector(List $_) {
    my @l = .list;

    my $elem = do with @l.head<qname> {
        $.xpath(@l.shift);
    }
    else {
        '*';
    }

    my @selections = @l.map({
        with $.xpath($_) {
            '[' ~ $_ ~ ']'
        }
        else {
            ''
        }
    }).join;

   $elem ~ @selections.join;
}

method xpath-string(Str $_) {
    "'" ~ .subst("'", "''", :g) ~ "'";
}

method to-xpath(Str:D $css-selectors) {
    my $obj = self;
    $_ .= new without $obj;
    my $actions = (require ::('CSS::Module::CSS3::Selectors::Actions')).new;
    if (require ::('CSS::Module::CSS3::Selectors')).parse($css-selectors, :rule<selectors>, :$actions) {
        $obj.xpath($/.ast);
    }
    else {
        fail "unable to parse CSS selector: $css-selectors";
    }
}


