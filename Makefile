.PHONY: all
all:

.PHONY: run
run: install
	bgrun ~/.computer-info/computer-info --daemon
	./install-crontab.sh

.PHONY: install
install:
	mkdir -p ~/.computer-info
	cp computer-info.sh ~/.computer-info/computer-info
	cp analyze ~/.computer-info/analyze-computer-info
	cp analyze.py ~/.computer-info
	! [ -d ~/bin ] || (cd ~/bin && ln -sf ~/.computer-info/computer-info && \
		ln -sf ~/.computer-info/analyze-computer-info)
