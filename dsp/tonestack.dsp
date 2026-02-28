import("stdfaust.lib");
ts_lib = library("tonestacks.lib");

// Dual Rectifier FMV tone stack (D.T. Yeh bilinear-transformed 3rd-order IIR)
// Key difference from Mesa Mark series: R2 = 1M (vs 250k) for deeper bass response

dual_rect_tonestack(t, m, l) = ts_lib.tonestack(C1, C2, C3, R1, R2, R3, R4, t, m, l)
with {
    R1 = 250e3;   // Treble pot
    R2 = 1e6;     // Bass pot (1M — key Dual Rectifier value)
    R3 = 25e3;    // Mid pot
    R4 = 33e3;    // Fixed resistor (Dual Rectifier schematic)
    C1 = 250e-12; // 250pF
    C2 = 22e-9;   // 22nF (was 100nF — Mesa Mark series value)
    C3 = 22e-9;   // 22nF (was 47nF — Mesa Mark series value)
};
