include common.mk

all:
	@echo "no default make rule defined"

help:
	@echo ""
	@echo ""
	@echo "pod-charlesreid Makefile:"
	@echo ""
	@echo ""
	@echo "This Makefile contains rules for setting up pod-charlesreid1"
	@echo ""
	@echo "make help:           Get help"
	@echo ""
	@echo "make templates:      Render each .j2 template file in this and all subdirectories"
	@echo "                     (uses environment variables to populate Jinja variables)"
	@echo ""
	@echo "make list-templates: List each .j2 template file that will be rendered by a 'make template' command"
	@echo ""
	@echo "make clean-templates: Remove each rendered .j2 template"
	@echo ""
	@echo "make backups:        Create backups of every service (gitea, wiki database, wiki files) in ~/backups"
	@echo ""
	@echo "make clean-backups:  Remove files from ~/backups directory older than 30 days"
	@echo ""
	@echo "make clone-www:      Create the /www directory structure for charlesreid1.com"
	@echo ""
	@echo "make pull-www:       Update the contents of the /www directory structure for charlesreid1.com"
	@echo ""
	@echo ""
	@echo "make install:        Install and start systemd service to run pod-charlesreid1."
	@echo "                     Also install and start systemd service for pod-charlesreid1 backup services"
	@echo "                     for each service (gitea/mediawiki/mysql) part of pod-charlesreid1."
	@echo ""
	@echo "make uninstall:      Remove all systemd startup services and timers part of pod-charlesreid1"
	@echo ""

templates:
	python3 $(POD_CHARLESREID1_DIR)/scripts/apply_templates.py

list-templates:
	@find * -name "*.j2"

clean-templates:
	python3 $(POD_CHARLESREID1_DIR)/scripts/clean_templates.py

backups: templates
	$(POD_CHARLESREID1_DIR)/scripts/backups/gitea_dump.sh
	$(POD_CHARLESREID1_DIR)/scripts/backups/wikidb_dump.sh
	$(POD_CHARLESREID1_DIR)/scripts/backups/wikifiles_dump.sh

clean-backups:
	$(POD_CHARLESREID1_DIR)/scripts/clean_templates.sh

clone-www: templates
	python3 $(POD_CHARLESREID1_DIR)/scripts/git_clone_www.py

pull-www: templates
	python3 $(POD_CHARLESREID1_DIR)/scripts/git_pull_www.py

install: templates
ifeq ($(shell which systemctl),)
	$(error Please run this make command on a system with systemctl installed)
endif
	cp $(POD_CHARLESREID1_DIR)/scripts/pod-charlesreid1.service /etc/systemd/system/pod-charlesreid1.service
	cp $(POD_CHARLESREID1_DIR)/scripts/backups/pod-charlesreid1-backups-gitea.{service,timer} /etc/systemd/system/.
	cp $(POD_CHARLESREID1_DIR)/scripts/backups/pod-charlesreid1-backups-wikidb.{service,timer} /etc/systemd/system/.
	cp $(POD_CHARLESREID1_DIR)/scripts/backups/pod-charlesreid1-backups-wikifiles.{service,timer} /etc/systemd/system/.
	systemctl daemon-reload
	systemctl enable pod-charlesreid1
	systemctl enable pod-charlesreid1-backups-gitea.timer
	systemctl enable pod-charlesreid1-backups-wikidb.timer
	systemctl enable pod-charlesreid1-backups-wikifiles.timer
	systemctl start pod-charlesreid1-backups-gitea.timer
	systemctl start pod-charlesreid1-backups-wikidb.timer
	systemctl start pod-charlesreid1-backups-wikifiles.timer

uninstall:
ifeq ($(shell which systemctl),)
	$(error Please run this make command on a system with systemctl installed)
endif
	systemctl disable pod-charlesreid1
	systemctl disable pod-charlesreid1-backups-gitea.timer
	systemctl disable pod-charlesreid1-backups-wikidb.timer
	systemctl disable pod-charlesreid1-backups-wikifiles.timer
	systemctl stop pod-charlesreid1
	systemctl stop pod-charlesreid1-backups-gitea.timer
	systemctl stop pod-charlesreid1-backups-wikidb.timer
	systemctl stop pod-charlesreid1-backups-wikifiles.timer
	rm -f /etc/systemd/system/pod-charlesreid1.service
	rm -f /etc/systemd/system/pod-charlesreid1-backups-gitea.{service,timer}
	rm -f /etc/systemd/system/pod-charlesreid1-backups-wikidb.{service,timer}
	rm -f /etc/systemd/system/pod-charlesreid1-backups-wikifiles.{service,timer}
	systemctl daemon-reload

.PHONY: help
