module wave_square(
    input  [31:0] phase,
    output [13:0] wave_data
);

    assign wave_data = phase[31] ? 14'h3fff : 14'h0000;

endmodule

