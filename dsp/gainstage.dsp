import("stdfaust.lib");
tr = library("triode.dsp");

// Complete gain stage modeling real circuit components:
//   Coupling cap + grid leak resistor  →  AC coupling highpass
//   Cathode bypass capacitor           →  frequency-dependent gain (high shelf)
//   12AX7 triode                       →  ADAA waveshaping + phase inversion
//   Plate load + parasitic capacitance →  gentle lowpass at ~12kHz

gainstage(drive, sag, coupling_fc, bypass_fc, bypass_boost_db) =
    fi.highpass(1, coupling_fc) :
    fi.highshelf(1, bypass_boost_db, bypass_fc) :
    tr.triode(drive * sag) :
    fi.lowpass(1, 12000);
