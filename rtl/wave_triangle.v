module wave_triangle(
    input  [31:0] phase,
    output [13:0] wave_data
);

    wire [13:0] ramp;

    assign ramp = phase[30:17];
    assign wave_data = phase[31] ? ~ramp : ramp;

endmodule

