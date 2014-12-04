ANTIPHONS = $(addprefix ant,1 2 3 4 5) $(addprefix ant-magn-vesp,1 2) ant-ben-laud $(addprefix matant,1 2 3 4 5 6 7 8 9)
RESPONSORIES = $(addprefix matresp,1 2 4 5 6 7 8)
PROPERSOFTHEMASS = alleluia-VidimusStellam communio-VidimusStellam graduale-OmnesDeSaba introitus-EcceAdvenit \
		   offertorium-RegesTharsis
SCORES = $(addsuffix .tex, $(ANTIPHONS) $(RESPONSORIES) $(PROPERSOFTHEMASS))
all: test.pdf neumetable.pdf
test.pdf: test.tex $(SCORES) gregall.ttf SGModern.ttf gregall.tex
	lualatex $< && lualatex $<
neumetable.pdf: neumetable.tex gregall.ttf SGModern.ttf gregall.tex
	lualatex $< && lualatex $<
$(SCORES): %.tex: %.gabc
	sed 's/+Z)/Z)/' $< | gregorio -s -o $@
clean:
	rm -f $(SCORES) *.gaux *.aux *.log *~
