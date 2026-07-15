module dac_ad9767_if(
    input         dac_clk,
    input         rst_n,
    input         global_enable,
    input  [13:0] ch_a_data,
    input  [13:0] ch_b_data,
    output        DACA_CLK,
    output        DACB_CLK,
    output        DACA_WRT,
    output        DACB_WRT,
    output reg [13:0] DACA_DATA,
    output reg [13:0] DACB_DATA
);

    localparam [13:0] DAC_MID_CODE = 14'h2000;

    assign DACA_CLK = dac_clk;
    assign DACB_CLK = dac_clk;
    assign DACA_WRT = dac_clk;
    assign DACB_WRT = dac_clk;

    always @(posedge dac_clk or negedge rst_n) begin
        if (!rst_n) begin
            DACA_DATA <= DAC_MID_CODE;
            DACB_DATA <= DAC_MID_CODE;
        end else if (global_enable) begin
            DACA_DATA <= ch_a_data;
            DACB_DATA <= ch_b_data;
        end else begin
            DACA_DATA <= DAC_MID_CODE;
            DACB_DATA <= DAC_MID_CODE;
        end
    end

endmodule

