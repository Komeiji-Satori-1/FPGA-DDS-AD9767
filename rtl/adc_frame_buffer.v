module adc_frame_buffer(
    input         wr_clk,
    input         wr_en_ch1,
    input         wr_en_ch2,
    input  [9:0]  wr_addr,
    input  [11:0] wr_data_ch1,
    input  [11:0] wr_data_ch2,
    input  [9:0]  rd_addr,
    output [11:0] rd_data_ch1,
    output [11:0] rd_data_ch2
);

    reg [11:0] ch1_mem [0:1023];
    reg [11:0] ch2_mem [0:1023];

    integer i;

    always @(posedge wr_clk) begin
        if (wr_en_ch1)
            ch1_mem[wr_addr] <= wr_data_ch1;
        if (wr_en_ch2)
            ch2_mem[wr_addr] <= wr_data_ch2;
    end

    assign rd_data_ch1 = ch1_mem[rd_addr];
    assign rd_data_ch2 = ch2_mem[rd_addr];

endmodule
