include common.mk

all:
	@echo "no default make rule defined"

help:
	cat Makefile

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
