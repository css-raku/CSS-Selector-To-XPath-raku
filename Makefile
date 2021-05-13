DocProj=css-raku.github.io
DocRepo=https://github.com/css-raku/$(DocProj)
DocLinker=../$(DocProj)/etc/resolve-links.raku

all : doc

doc : README.md

README.md : lib/CSS/Selector/To/XPath.rakumod
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

