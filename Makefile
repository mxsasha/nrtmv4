NAME=draft-spaghetti-grow-nrtm-v4

all: $(NAME).xml
	xml2rfc $(NAME).xml --html --text

clean:
	rm -f *.html *.txt
