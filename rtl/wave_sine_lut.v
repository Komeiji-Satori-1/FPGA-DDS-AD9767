module wave_sine_lut(
    input         clk,
    input  [13:0] addr,
    output reg [13:0] data
);

    (* ram_init_file = "mem/sine14_16384.mif" *) reg [13:0] rom [0:16383];

    initial begin
        data = 14'h2000;
        $readmemh("mem/sine14_16384.hex", rom);
    end

    always @(posedge clk) begin
        data <= rom[addr];
    end

endmodule
