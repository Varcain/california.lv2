import("stdfaust.lib");

// Cold clipper: Dual Rectifier V3b cathode follower
// Asymmetric hard clip (+0.8 / -0.4) generates even-order harmonics
// and gives the signature "rectified" buzz character.
// ADAA2 antialiasing — piecewise linear clip has exact polynomial antiderivatives.

coldclipper(mix) = _ <: (_, (*(pregain) : clip_core : *(postgain))) : crossfade(mix)
with {
    hi = 0.8;
    lo = -0.4;
    pregain = 1.0;              // push signal into clipping range
    postgain = 1.0 / hi;       // normalize max positive output to ~1.0

    crossfade(m, dry, wet) = dry * (1.0 - m) + wet * m;

    clip_core = aa.ADAA2(EPS, f, F1, F2)
    with {
        EPS = 1.0 / ma.SR;

        f(x) = max(min(x, hi), lo);

        F1(x) = ba.if(x < lo,
                    lo * x - lo * lo * 0.5,
                    ba.if(x > hi,
                        hi * x - hi * hi * 0.5,
                        x * x * 0.5));

        F2(x) = ba.if(x < lo,
                    lo * x * x * 0.5 - lo * lo * x * 0.5 + lo * lo * lo / 6.0,
                    ba.if(x > hi,
                        hi * x * x * 0.5 - hi * hi * x * 0.5 + hi * hi * hi / 6.0,
                        x * x * x / 6.0));
    };
};
