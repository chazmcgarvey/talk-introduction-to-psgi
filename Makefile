
SLIDES  = introduction-to-psgi
BROWSER = chrome
DOT     = dot
PLACKUP = plackup

dotfiles = $(shell find . -iname '*.dot')
svgfiles = $(patsubst %.dot,%.svg,$(dotfiles))

all: $(svgfiles)

clean:
	rm -f slides-offline.html remark.min.js $(SLIDES).pdf $(svgfiles)

offline: slides-offline.html remark.min.js $(svgfiles)

pdf: $(SLIDES).pdf

run: $(svgfiles)
	$(BROWSER) slides.html

run-app: offline
	$(PLACKUP)

run-offline: offline
	$(BROWSER) slides-offline.html

%.svg: %.dot
	$(DOT) -Tsvg -o$@ $<

$(SLIDES).pdf: slides.html $(wildcard css/*) $(wildcard img/*) $(svgfiles)
	docker run --rm -v `pwd`:/pwd astefanutti/decktape /pwd/slides.html /pwd/$(SLIDES).pdf

slides-offline.html: slides.html
	sed -e '1 a <!-- This file is auto-generated - DO NOT EDIT!!! -->' \
	    -e 's!https://.*remark-latest\.min\.js!remark.min.js!' <$< >$@

remark.min.js:
	curl -Lo $@ https://gnab.github.io/remark/downloads/remark-latest.min.js

.PHONY: all clean offline pdf run run-app run-offline

