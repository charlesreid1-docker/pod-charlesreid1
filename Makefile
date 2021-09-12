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
	@echo "--------------------------------------------------"
	@echo "                   Templates:"
	@echo ""
	@echo "make templates:      Render each .j2 template file in this and all subdirectories"
	@echo "                     (uses environment variables to populate Jinja variables)"
	@echo ""
	@echo "make list-templates: List each .j2 template file that will be rendered by a 'make template' command"
	@echo ""
	@echo "make clean-templates: Remove each rendered .j2 template"
	@echo ""
	@echo "--------------------------------------------------"
	@echo "                   Backups:"
	@echo ""
	@echo "make backups:        Create backups of every service (wiki database, wiki files) in ~/backups"
	@echo ""
	@echo "make clean-backups:  Remove files from ~/backups directory older than 30 days"
	@echo ""
	@echo "--------------------------------------------------"
	@echo "                   MediaWiki:"
	@echo ""
	@echo "make mw-build-extensions  Build the MediaWiki extensions directory"
	@echo ""
	@echo "make mw-fix-extensions    Copy the built extensions directory into the MW container"
	@echo ""
	@echo "make mw-fix-localsettings Copy the LocalSettings.php file into the MW container"
	@echo ""
	@echo "make mw-fix-skins         Copy the skins directory into the MW container"
	@echo ""
	@echo "--------------------------------------------------"
	@echo "                   /www Directory:"
	@echo ""
	@echo "make clone-www:      Create the /www directory structure for charlesreid1.com"
	@echo ""
	@echo "make pull-www:       Update the contents of the /www directory structure for charlesreid1.com"
	@echo ""
	@echo "--------------------------------------------------"
	@echo "                   Startup Services:"
	@echo ""
	@echo "make install:        Install and start systemd service to run pod-charlesreid1."
	@echo "                     Also install and start systemd service for pod-charlesreid1 backup services"
	@echo "                     for each service (mediawiki/mysql) part of pod-charlesreid1."
	@echo ""
	@echo "make uninstall:      Remove all systemd startup services and timers part of pod-charlesreid1"
	@echo ""

# Templates

templates:
	python3 $(POD_CHARLESREID1_DIR)/scripts/apply_templates.py

list-templates:
	@find * -name "*.j2"

clean-templates:
	python3 $(POD_CHARLESREID1_DIR)/scripts/clean_templates.py

# Backups

backups:
	$(POD_CHARLESREID1_DIR)/scripts/backups/wikidb_dump.sh
	$(POD_CHARLESREID1_DIR)/scripts/backups/wikifiles_dump.sh

clean-backups:
	$(POD_CHARLESREID1_DIR)/scripts/clean_templates.sh

# MediaWiki

mw-build-extensions:
	$(POD_CHARLESREID1_DIR)/scripts/mw/build_extensions_dir.sh

mw-fix-extensions: mw-build-extensions
	$(POD_CHARLESREID1_DIR)/scripts/mw/build_extensions_dir.sh

mw-fix-localsettings:
	$(POD_CHARLESREID1_DIR)/scripts/mw/fix_LocalSettings.sh

mw-fix-skins:
	$(POD_CHARLESREID1_DIR)/scripts/mw/fix_skins.sh

# /www Dir

clone-www:
	python3 $(POD_CHARLESREID1_DIR)/scripts/git_clone_www.py

pull-www:
	python3 $(POD_CHARLESREID1_DIR)/scripts/git_pull_www.py

install:
ifeq ($(shell which systemctl),)
	$(error Please run this make command on a system with systemctl installed)
endif
	sudo cp $(POD_CHARLESREID1_DIR)/scripts/pod-charlesreid1.service /etc/systemd/system/pod-charlesreid1.service
	sudo cp $(POD_CHARLESREID1_DIR)/scripts/backups/pod-charlesreid1-backups-wikidb.{service,timer} /etc/systemd/system/.
	sudo cp $(POD_CHARLESREID1_DIR)/scripts/backups/pod-charlesreid1-backups-wikifiles.{service,timer} /etc/systemd/system/.
	sudo cp $(POD_CHARLESREID1_DIR)/scripts/backups/pod-charlesreid1-backups-gitea.{service,timer} /etc/systemd/system/.
	sudo systemctl daemon-reload
	sudo systemctl enable pod-charlesreid1
	sudo systemctl enable pod-charlesreid1-backups-wikidb.timer
	sudo systemctl enable pod-charlesreid1-backups-wikifiles.timer
	sudo systemctl enable pod-charlesreid1-backups-gitea.timer
	sudo systemctl start pod-charlesreid1-backups-wikidb.timer
	sudo systemctl start pod-charlesreid1-backups-wikifiles.timer
	sudo systemctl start pod-charlesreid1-backups-gitea.timer

uninstall:
ifeq ($(shell which systemctl),)
	$(error Please run this make command on a system with systemctl installed)
endif
	-sudo systemctl disable pod-charlesreid1
	-sudo systemctl disable pod-charlesreid1-backups-wikidb.timer
	-sudo systemctl disable pod-charlesreid1-backups-wikifiles.timer
	-sudo systemctl disable pod-charlesreid1-backups-gitea.timer
	-sudo systemctl stop pod-charlesreid1
	-sudo systemctl stop pod-charlesreid1-backups-wikidb.timer
	-sudo systemctl stop pod-charlesreid1-backups-wikifiles.timer
	-sudo systemctl stop pod-charlesreid1-backups-gitea.timer
	-sudo rm -f /etc/systemd/system/pod-charlesreid1.service
	-sudo rm -f /etc/systemd/system/pod-charlesreid1-backups-wikidb.{service,timer}
	-sudo rm -f /etc/systemd/system/pod-charlesreid1-backups-wikifiles.{service,timer}
	-sudo rm -f /etc/systemd/system/pod-charlesreid1-backups-gitea.{service,timer}
	sudo systemctl daemon-reload

.PHONY: help
