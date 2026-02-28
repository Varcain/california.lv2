import("stdfaust.lib");

// 12AX7 triode model: Koren-inspired waveshaper with 4x naive oversampling
// Models three key characteristics of the Koren equations:
//   softplus(k*x)  →  sharp grid cutoff knee (vs gradual tanh)
//   pow(E1, 1.4)   →  fractional-exponent compression curve
//   tanh() wrapper  →  output saturation from plate voltage drop
// Phase inversion models real triode plate output

triode(drive) = *(drive) : +(bias) : oversample4(koren_sat) : *(-1) : fi.dcblocker
with {
    bias = -0.2;

    koren_sat(x) = ma.tanh(gain * (raw - dc))
    with {
        knee = 4.0;      // softplus sharpness (Kp-derived)
        offset = 0.05;   // ~1/mu bias shift
        ex = 1.4;        // Koren plate current exponent
        gain = 2.0;      // drive into output saturation

        softplus(z) = log(1.0 + exp(min(z, 20.0)));  // clamp prevents exp overflow
        e1 = softplus(knee * (x + offset));
        raw = pow(max(e1, 1e-10), ex);  // max guard prevents pow(0,1.4) NaN

        e1_0 = softplus(knee * offset);          // E1 at quiescent point
        dc = pow(max(e1_0, 1e-10), ex);          // DC offset for centering
    };

    // 4x naive oversampling: linear interpolation up, box-car (average) down
    // Combined alias rejection ~-26dB, sufficient with per-stage 12kHz LPF
    oversample4(f, x) = (f(p0) + f(p1) + f(p2) + f(p3)) * 0.25
    with {
        prev = x';
        p0 = prev * 0.75 + x * 0.25;
        p1 = prev * 0.50 + x * 0.50;
        p2 = prev * 0.25 + x * 0.75;
        p3 = x;
    };
};
