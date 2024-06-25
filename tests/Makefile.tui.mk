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
all:  tux.bootstrap demo.tux

include compose.mk

# demo: io.env demo.help 
demo.tux:
	# start commander TUI and stop after 5s
	./compose.mk flux.apply.later/5/tux.panic tux.commander || true
	./k8s.mk flux.apply.later/8/tux.panic docker.commander || true
	make tux.mux/flux.timeout/2/io.bash,flux.timeout/2/io.bash

demo.help: 
	# make io.print.div label="${cyan}${@}${no_ansi}"
	# make help
