.PHONY: all
all:

.PHONY: install
install:
	cp computer-info.sh ~/bin/computer-info

.PHONY: install-crontabs
install-crontabs:
	urssh --each \
		--command='(crontab -l; echo "*/5 * * * * ~/bin/computer-info --file") | crontab -'

.PHONY: uninstall-crontabs
uninstall-crontabs:
	urssh --each --command='crontab -l | grep -v computer-info | crontab -'
