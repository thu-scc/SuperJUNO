# Keep Make and Python runs on the same pipeline, timing, and comparison code.
PYTHON ?= python
COMPARE ?= 0
INPUTS := data/ser_truth_J25.7.4+.h5 data/sim.h5 data/PMT_J26.4.0.h5 \
          data/junoid_J25.3.0.pq data/J25.3.0.PMTPos_CD_LPMT.csv
SOURCES := $(wildcard src/*.py src/analysis/*.py src/analysis/fsmp/*.py src/analysis/fsmp/*.cu) \
           scripts/run.py test/compare_PE.py test/compare_tvE.py test/comparison.py

ifeq ($(COMPARE),1)
COMPARE_FLAG := --compare
else ifeq ($(COMPARE),0)
COMPARE_FLAG :=
else
$(error COMPARE must be 0 or 1)
endif

.DEFAULT_GOAL := help
.PHONY: help
# Preserve the canonical output when it is a prerequisite of a legacy alias.
.SECONDARY:

help:
	@printf '%s\n' \
	  'make output/tvE/<id>.h5             Build if inputs or code changed' \
	  'make -B output/tvE/<id>.h5 COMPARE=1   Required for scored runs' \
	  'make tvE/<id>.h5                   Legacy alias; outputs stay in output/' \
	  'make test/PE/<id>                  Compare existing PE outputs only' \
	  'make test/tvE/<id>                 Compare existing reconstruction only' \
	  'Set PYTHON=/path/to/python to choose an interpreter. Run GPU jobs via Slurm.'

# Normal timestamp-based rebuilds; scored runs must use -B.
output/tvE/%.h5: data/raw/%.h5 $(INPUTS) $(SOURCES) Makefile pyproject.toml
	"$(PYTHON)" scripts/run.py "$*" $(COMPARE_FLAG)

tvE/%.h5: output/tvE/%.h5
	@:

# These targets never build missing outputs or generate pipeline timing.
test/PE/%:
	"$(PYTHON)" test/compare_PE.py "data/ana_PE/$*.pq" "output/PE/$*.pq"

test/tvE/%:
	"$(PYTHON)" test/compare_tvE.py "data/ana_tvE/$*.h5" "output/tvE/$*.h5"
