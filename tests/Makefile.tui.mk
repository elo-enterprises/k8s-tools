##
# TUI test suite for compose.mk 
#
# Usage: 
#
#   # from project root
#   $ make tui-test
##
SHELL := bash
MAKEFLAGS=-s --warn-undefined-variables
.SHELLFLAGS := -eu -c
.DEFAULT_GOAL := all 
all:  tux.bootstrap demo

include compose.mk

demo: io.env demo.help demo.crux demo.cruxd io.env

demo.crux:
	make crux.mux/flux.timeout/2/io.bash

demo.cruxd:
	make crux.mux.detach/flux.timeout/5/io.bash

demo.help: 
	# make io.print.div label="${CYAN}${@}${NO_ANSI}"
	# make help
