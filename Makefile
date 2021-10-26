NAME=draft-spaghetti-grow-nrtm-v4

all: $(NAME).xml
	xml2rfc $(NAME).xml --html --text -s "Artwork too wide" -s "Section too wide" -s "Middle too wide" -s "Too long line"

clean:
	rm -f *.html *.txt
