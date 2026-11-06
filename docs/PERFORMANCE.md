# Beem 440 measurements

Projector Sunrise Fast uses a native-resolution static JPEG, RGB565 wallpaper decoding, short launcher motion of up to 90 ms, reduced visual effects and Android animation scales of 0.5.

| Measurement | Original Cinematic | Final Sunrise Fast |
|---|---:|---:|
| Launcher cold start, median | 907 ms | 845 ms |
| Cold-start maximum | 2,676 ms | 851 ms |
| Cold starts measured | 5 | 5 |
| Launcher memory, PSS | 55 MB | 43 MB |
| Launcher idle CPU | 0.1% | 0.1% |
| Whole-device idle CPU | 12.0% | 12.3% |

The measured memory difference was 12 MB and the median cold-start difference was 62 ms. Whole-device idle CPU did not improve. Five starts are too few to establish a reliable worst-case startup time; with this sample count, the reported p95 is just the maximum. Sanitized measurement exports are included for [before](../measurements/before.json) and [after](../measurements/after.json).

## Method

Measurements used the pinned upstream `tools/bench.py`, the same configured launcher APK and the real Beem 440. Both comparison runs included five cold starts, ten return-to-Home attempts and a 60-second idle measurement.

The original run attempted 108 navigation samples; the final run attempted 12. Neither produced an accepted frame-timing sample. **FPS, navigation latency, movement time, jank and return-to-Home latency were not established.** An absence of accepted timing samples does not mean zero rendered frames.

The navigation passes also mean different preconditioning. Treat the result as a practical comparison on this unit, not a controlled hardware benchmark or a guarantee for another device.

## Wallpaper change

The generated source PNG is 1672 × 941 and 1,688,578 bytes. The final runtime export is a 1280 × 720 JPEG at quality 90, 65,848 bytes. The original image is retained separately.

An intermediate PNG theme measured a 1,155 ms median cold start and 42 MB PSS. It was superseded by the JPEG profile. The final table therefore compares original Cinematic against the deployed JPEG profile, not against the intermediate theme.

## Limits

- Shorter Android animations reduce the duration of transitions. They do not accelerate the processor, network or video decoder.
- The Photos screensaver and extra old-SDK cleanup were added after the final benchmark. No measured improvement is attributed to them.
- Screensaver resource use, streaming quality and frame rate were not part of this Home benchmark.
- There is no evidence here for USB RAM expansion, an overclock, a universal background-process limit or a RAM-booster app.
- Detailed original diagnostics remain private because they can contain device identifiers and network information.

For a new comparison, use the same sequence and configuration in both runs, capture the state of the device and report failed measurements as failed rather than treating them as improvements.
