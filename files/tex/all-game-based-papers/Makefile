# Builds the game-based-proofs reading list and drops the PDF where the website
# serves it from (files/all-game-based-papers.pdf), next to all-uc-papers.pdf.
#
#   make          build the PDF and install it into files/
#   make pdf      build it here only, without installing
#   make check    re-verify every DOI and ePrint number in refs.bib (needs network)
#   make clean    remove LaTeX's build droppings
#   make distclean  ... and the PDF in this directory

NAME    := all-game-based-papers
# Where the site serves the PDF from: two directories up (files/tex/<here> -> files/).
INSTALL := ../..

LATEX  := pdflatex -interaction=nonstopmode -halt-on-error
BIBTEX := bibtex

.PHONY: all pdf install check clean distclean

all: install

# bibtex needs the .aux from a first pass; the two trailing latex runs resolve
# the citations and then the page numbers/PDF outline.
pdf: $(NAME).pdf
$(NAME).pdf: $(NAME).tex refs.bib
	$(LATEX) $(NAME).tex
	$(BIBTEX) $(NAME)
	$(LATEX) $(NAME).tex
	$(LATEX) $(NAME).tex
	@echo
	@grep -c '^\\bibitem' $(NAME).bbl | xargs echo ">>> references:"

install: $(NAME).pdf
	cp -f $(NAME).pdf $(INSTALL)/$(NAME).pdf
	@echo ">>> installed $(INSTALL)/$(NAME).pdf"

# Guards against the one error that matters in a reading list: a citation that
# points at the wrong paper. For every doi= and every eprint URL in refs.bib,
# fetch the title from the source and print it next to the bib entry's own
# title, so a mismatch is visible. Deliberately not part of the default build:
# it is slow and needs the network.
check:
	@python3 check-refs.py refs.bib

clean:
	rm -f $(NAME).aux $(NAME).log $(NAME).out $(NAME).bbl $(NAME).blg

distclean: clean
	rm -f $(NAME).pdf
