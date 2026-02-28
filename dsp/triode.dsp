import("stdfaust.lib");

// 12AX7 triode model with first-order ADAA antialiasing
// Asymmetric tanh waveshaper modeling plate characteristics:
//   Soft clipping in cutoff (negative grid), harder at grid current (positive grid)
//   Phase inversion (plate output inverts signal)

triode(drive) = *(drive) : +(bias) : asymmetric_sat : *(-1) : fi.dcblocker
with {
    // 12AX7 curve-fitting parameters
    km = 1.7;    // steeper grid conduction knee (was 1.0)
    ka = 0.5;    // slightly harder cutoff region (was 0.4)
    kp = 0.85;   // more weight on hard curve (was 0.7)
    bias = -0.2; // shifts operating point for even-order harmonics

    // First-order ADAA waveshaper (from aanl.lib)
    // f(x) = kp*tanh(km*x) + (1-kp)*tanh(ka*x)
    // F1(x) = antiderivative = kp/km*ln(cosh(km*x)) + (1-kp)/ka*ln(cosh(ka*x))
    asymmetric_sat = aa.ADAA1(EPS, f, F1)
    with {
        EPS = 1.0 / ma.SR;
        f(x) = kp * ma.tanh(km * x) + (1 - kp) * ma.tanh(ka * x);
        F1(x) = kp / km * log(aa.Rcosh(km * x)) +
                (1 - kp) / ka * log(aa.Rcosh(ka * x));
    };
};
