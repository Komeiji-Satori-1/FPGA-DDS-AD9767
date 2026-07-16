# AD9226 RTL Extension Change Log

## 2026-07-16

### ADC acquisition core scaffold

Files added:
```text
rtl/adc_clk_gen.v
rtl/adc_frame_buffer.v
rtl/adc_capture.v
rtl/adc_readout.v
rtl/adc_irq.v
rtl/adc_top.v
```

Files updated:
```text
rtl/spi_slave.v
rtl/reg_file.v
rtl/wavegen_top.v
wavegen.qsf
```

Why:
```text
Add a first-pass AD9226 acquisition path with SPI-configurable control, frame buffering,
interrupt signaling, and raw sample readout support.
```

Scope:
```text
Dual-channel capture, single-channel enable, 1024-point frames, interrupt generation,
and readback of buffered samples through the existing SPI protocol.
```

Validation:
```text
Manual structural review only. No Quartus synthesis run was available in the current shell.
```

Pre-commit review fixes:
```text
1. Raw readout now honors the latched channel enable bits for each completed frame.
   Single-channel capture returns only the enabled channel; dual-channel capture still
   returns CH1 first and CH2 second.
2. ADC sample_tick now fires on the falling half-cycle of the generated ADC clock, giving
   AD9226 output data half a sample period to settle after the active clock edge.
3. QSF now assigns 3.3-V LVTTL IO standards to ADC clocks and all ADC data pins.
```

Open items:
```text
1. ADC_IRQ is assigned to PIN_A20 as a spare J6-side pin candidate; confirm board wiring before hardware test.
2. Confirm the final ADC sample phase against board timing and oscilloscope captures.
3. Add simulation testbench for capture, frame ready, and SPI readback.
```
