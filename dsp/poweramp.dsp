import("stdfaust.lib");

// Power amp: phase inverter → push-pull 6L6 → output transformer
// with negative feedback loop controlled by Presence

poweramp(master_drive, presence, sag) = (+ : *(master_drive) : core(sag)) ~ nfb(presence)
with {
    core(sag) = phase_inverter : push_pull_6l6(sag) : output_transformer;

    // 12AX7 long-tail pair with ~5% gain imbalance → even-order harmonics
    phase_inverter = _ <: (*(1.025), *(-0.975));

    // Push-pull 6L6 class AB: rational polynomial soft saturation
    // Output transformer inverts one phase so both halves add constructively
    push_pull_6l6(sag) = (tube6l6(sag), tube6l6_neg(sag)) :> _;
    soft_clip(x) = x * (1.0 + 0.2 * x) / (1.0 + abs(0.8 * x));
    tube6l6(sag, x) = sag * soft_clip(x);
    tube6l6_neg(sag, x) = 0 - sag * soft_clip(x);

    // Output transformer: 2nd-order bandpass (70Hz–7kHz) + soft core saturation
    output_transformer = fi.highpass(2, 70) : fi.lowpass(2, 7000) : xfmr_sat
    with {
        xfmr_sat(x) = ma.tanh(x * 0.8) * 1.25;
    };

    // Negative feedback with Presence control
    // Higher presence → lower LP cutoff → less HF in feedback → brighter output
    nfb(pres) = fi.lowpass(1, nfb_fc(pres)) : *(-0.15);
    nfb_fc(pres) = 3500.0 * pow(500.0 / 3500.0, pres);
};
