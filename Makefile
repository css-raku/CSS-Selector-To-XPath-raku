DocProj=css-raku.github.io
DocRepo=https://github.com/css-raku/$(DocProj)
DocLinker=../$(DocProj)/etc/resolve-links.raku

$(DocLinker) :
	(cd .. && git clone $(DocRepo) $(DocProj))

all : doc

doc : Pod-To-Markdown-installed README.md $(DocLinker)

Pod-To-Markdown-installed :
	@raku -M Pod::To::Markdown -c

README.md : lib/CSS/Selector/To/XPath.rakumod
	@raku -I . -c $<
	(\
	    echo '[![Build Status](https://travis-ci.org/css-raku/CSS-Selector-To-XPath-raku.svg?branch=master)](https://travis-ci.org/css-raku/CSS-Selector-To-XPath-raku)'; \
            echo '';\
            raku -I . --doc=Markdown $< \
	    | TRAIL=CSS/Selector/To/XPath raku -p -n $(DocLinker) \
        ) > README.md

test :
	@prove -e"raku -I ." t

loudtest :
	@prove -e"raku -I ." -v t

