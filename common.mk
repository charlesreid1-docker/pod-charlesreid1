SHELL=/bin/bash

ifeq ($(shell echo ${POD_CHARLESREID1_DIR}),)
$(error Environment variable POD_CHARLESREID1_DIR not defined. Please run "source environment" in the repo root directory before running make commands)
endif

ifeq ($(shell which python3),)
$(error Please install python3)
endif

ifeq ($(shell which aws),)
$(error Please install aws-cli)
endif
