module adc_clk_gen(
    input         clk,
    input         rst_n,
    input         enable,
    input  [15:0] half_period,
    output reg    adc_clk,
    output reg    sample_tick
);

    reg [15:0] div_cnt;

    wire [15:0] half_period_eff;

    assign half_period_eff = (half_period < 16'd2) ? 16'd2 : half_period;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt <= 16'd0;
            adc_clk <= 1'b0;
            sample_tick <= 1'b0;
        end else if (!enable) begin
            div_cnt <= 16'd0;
            adc_clk <= 1'b0;
            sample_tick <= 1'b0;
        end else if (div_cnt == half_period_eff - 1'b1) begin
            div_cnt <= 16'd0;
            sample_tick <= adc_clk;
            adc_clk <= ~adc_clk;
        end else begin
            div_cnt <= div_cnt + 1'b1;
            sample_tick <= 1'b0;
        end
    end

endmodule
