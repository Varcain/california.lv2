declare name "California";
declare description "Mesa Boogie Dual Rectifier Simulation";
declare version "1.0";
declare license "GPL";

import("stdfaust.lib");
gs   = library("gainstage.dsp");
ts   = library("tonestack.dsp");
pa   = library("poweramp.dsp");
rect = library("rectifier.dsp");
cc   = library("coldclipper.dsp");

process = amp_chain
with {
    // --- UI Controls (all continuous params smoothed with si.smoo) ---
    gain_param = hslider("[0]Gain", 0.5, 0, 1, 0.01) : si.smoo;
    bass       = hslider("[1]Bass", 0.5, 0, 1, 0.01) : si.smoo;
    mid        = hslider("[2]Mid", 0.5, 0, 1, 0.01) : si.smoo;
    treble     = hslider("[3]Treble", 0.5, 0, 1, 0.01) : si.smoo;
    presence   = hslider("[4]Presence", 0.5, 0, 1, 0.01) : si.smoo;
    master     = hslider("[5]Master", 0.5, 0, 1, 0.01) : si.smoo;
    channel    = nentry("[6]Channel [lv2:integer] [lv2:enumeration] [lv2:scalePoint Clean 0 Vintage 1 Modern 2]", 0, 0, 2, 1) : int;
    rect_mode  = nentry("[7]Rectifier [lv2:integer] [lv2:enumeration] [lv2:scalePoint Tube 0 Diode 1]", 0, 0, 1, 1) : int;
    output_db  = hslider("[8]Output [lv2:scalePoint -40dB -40 -20dB -20 -12dB -12 0dB 0]", -12, -40, 0, 0.1) : si.smoo;

    // --- Derived Values ---
    drive = ba.db2linear(gain_param * 40 - 20);  // log mapping: 0.1 to 10
    master_drive = ba.db2linear(master * 36 - 12);  // log mapping: -12dB to +24dB, pushes power amp into saturation
    output_level = ba.db2linear(output_db);

    // --- Gain Stages (per Dual Rectifier topology) ---
    //   Stage | Coupling fc | Bypass fc | Boost | Channels
    //   1     | 7.2 Hz      | 156 Hz    | +6dB  | All
    //   2     | 7.2 Hz      | 156 Hz    | +6dB  | All
    //   3     | 15.9 Hz     | 200 Hz    | +4dB  | Vintage, Modern
    //   4     | 31.8 Hz     | 250 Hz    | +3dB  | Modern only
    stage1(drv, sag) = gs.gainstage(drv, sag, 7.2,  156, 6);
    stage2(drv, sag) = gs.gainstage(drv, sag, 7.2,  156, 6);
    stage3(drv, sag) = gs.gainstage(drv, sag, 15.9, 200, 4);
    stage4(drv, sag) = gs.gainstage(drv, sag, 31.8, 250, 3);

    // Channel switching: Clean=2 stages, Vintage=3, Modern=4
    // Each optional stage is always computed (FAUST evaluates all paths)
    // but only selected when the channel threshold is met
    optional_stage(stg, threshold, ch) =
        _ <: (_, stg) : select2(ch > threshold);

    preamp(drv, sag, ch) =
        stage1(drv, sag) : stage2(drv, sag) :
        optional_stage(stage3(drv, sag), 0, ch) :
        optional_stage(stage4(drv, sag), 1, ch);

    // Per-channel cold clipper mix: Clean=bypass, Vintage=partial, Modern=full
    clipper_mix = select2(channel > 0, 0.0, select2(channel > 1, 0.6, 1.0));

    // --- Full Signal Chain ---
    amp_chain(x) = x :
        preamp(drive, sag, channel) :
        cc.coldclipper(clipper_mix) :
        ts.dual_rect_tonestack(treble, mid, bass) :
        *(ba.db2linear(22)) :  // post-tonestack recovery gain (V4 stage, compensates passive FMV tonestack loss)
        pa.poweramp(master_drive, presence, sag) :
        *(output_level)
    with {
        sag = rect.sag_envelope(rect_mode, x * drive);
    };
};
