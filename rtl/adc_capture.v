module adc_capture(
    input         clk,
    input         rst_n,
    input         sample_tick,
    input         acq_enable,
    input         one_shot,
    input         clear_fifo,
    input         ch1_enable,
    input         ch2_enable,
    input  [15:0] frame_len,
    input  [11:0] ad1_data,
    input  [11:0] ad2_data,
    output reg    wr_en_ch1,
    output reg    wr_en_ch2,
    output reg [9:0] wr_addr,
    output reg    frame_ready_pulse,
    output reg    overflow_pulse,
    output reg [15:0] sample_count
);

    reg capture_armed;
    reg shot_done;

    wire [15:0] frame_len_eff;
    wire frame_last;

    assign frame_len_eff = (frame_len == 16'd0) ? 16'd1024 :
                           (frame_len > 16'd1024) ? 16'd1024 : frame_len;
    assign frame_last = capture_armed && (sample_count + 16'd1 == frame_len_eff);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            capture_armed <= 1'b0;
            shot_done <= 1'b0;
            wr_en_ch1 <= 1'b0;
            wr_en_ch2 <= 1'b0;
            wr_addr <= 10'd0;
            frame_ready_pulse <= 1'b0;
            overflow_pulse <= 1'b0;
            sample_count <= 16'd0;
        end else begin
            frame_ready_pulse <= 1'b0;
            overflow_pulse <= 1'b0;
            wr_en_ch1 <= 1'b0;
            wr_en_ch2 <= 1'b0;

            if (clear_fifo) begin
                capture_armed <= 1'b0;
                shot_done <= 1'b0;
                wr_addr <= 10'd0;
                sample_count <= 16'd0;
            end else begin
                if (!acq_enable) begin
                    capture_armed <= 1'b0;
                    shot_done <= 1'b0;
                    sample_count <= 16'd0;
                end else if (!capture_armed && (!one_shot || !shot_done)) begin
                    capture_armed <= 1'b1;
                    sample_count <= 16'd0;
                    wr_addr <= 10'd0;
                end

                if (sample_tick && capture_armed) begin
                    wr_addr <= sample_count[9:0];
                    wr_en_ch1 <= ch1_enable;
                    wr_en_ch2 <= ch2_enable;

                    if (sample_count >= frame_len_eff) begin
                        overflow_pulse <= 1'b1;
                    end else if (frame_last) begin
                        frame_ready_pulse <= 1'b1;
                        sample_count <= 16'd0;
                        wr_addr <= 10'd0;
                        if (one_shot) begin
                            capture_armed <= 1'b0;
                            shot_done <= 1'b1;
                        end
                    end else begin
                        sample_count <= sample_count + 1'b1;
                    end
                end
            end
        end
    end

endmodule
