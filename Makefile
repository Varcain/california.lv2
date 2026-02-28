# California.lv2 — Mesa Boogie Dual Rectifier Simulation
# Build: faust2lv2 compiles .dsp → .lv2 bundle

FAUST2LV2 = faust2lv2
DSP       = dsp/california.dsp
BUNDLE    = dsp/california.lv2

# Double precision for ADAA correctness
FAUST_FLAGS = -double

INSTALL_DIR = $(HOME)/.lv2

.PHONY: all install clean

all: $(BUNDLE)

$(BUNDLE): dsp/california.dsp dsp/triode.dsp dsp/gainstage.dsp dsp/tonestack.dsp dsp/poweramp.dsp dsp/rectifier.dsp dsp/coldclipper.dsp
	$(FAUST2LV2) $(FAUST_FLAGS) $(DSP)

install: $(BUNDLE)
	mkdir -p $(INSTALL_DIR)
	cp -r $(BUNDLE) $(INSTALL_DIR)/california.lv2

clean:
	rm -rf $(BUNDLE)
