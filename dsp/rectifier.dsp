import("stdfaust.lib");

// Asymmetric attack/release envelope follower
ar_envelope(att, rel, x) = loop ~ _
with {
    loop(prev) = ba.if(abs(x) > prev,
                       prev + (1.0 - att_c) * (abs(x) - prev),
                       prev + (1.0 - rel_c) * (abs(x) - prev))
    with {
        att_c = exp(-1.0 / max(1, att * ma.SR));
        rel_c = exp(-1.0 / max(1, rel * ma.SR));
    };
};

// Rectifier sag model
// mode: 0 = Tube (bloom/compression, ~20ms recovery, up to 30% sag)
//        1 = Diode (tight/punchy, ~1ms recovery, minimal 2% sag)
// Returns sag factor (0.7–1.0) fed to all gain stages and power amp

sag_envelope(mode, x) = sag_factor
with {
    tube_sag  = 1.0 - 0.30 * min(1.0, ar_envelope(0.001, 0.020, x));
    diode_sag = 1.0 - 0.02 * min(1.0, ar_envelope(0.001, 0.001, x));
    sag_factor = select2(mode, tube_sag, diode_sag);
};
