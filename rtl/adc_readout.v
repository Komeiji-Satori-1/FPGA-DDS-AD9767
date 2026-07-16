module adc_readout(
    input         clk,
    input         rst_n,
    input         clear_fifo,
    input         frame_ready_pulse,
    input         read_pop,
    input         raw_enable,
    input  [1:0]  ch_enable,
    input  [15:0] frame_len,
    input  [11:0] rd_data_ch1,
    input  [11:0] rd_data_ch2,
    output reg    read_bank,
    output reg [9:0] read_index,
    output reg [31:0] read_word,
    output reg    read_valid_pulse,
    output reg    raw_block_ready_pulse,
    output reg    underflow_pulse
);

    reg read_armed;
    reg [1:0] active_ch_enable;
    reg [15:0] read_count;

    wire [15:0] frame_len_eff;
    wire [11:0] selected_sample;
    wire frame_end;

    assign frame_len_eff = (frame_len == 16'd0) ? 16'd1024 :
                           (frame_len > 16'd1024) ? 16'd1024 : frame_len;
    assign selected_sample = (read_bank == 1'b0) ? rd_data_ch1 : rd_data_ch2;
    assign frame_end = (read_count + 16'd1 == frame_len_eff);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_armed <= 1'b0;
            active_ch_enable <= 2'b00;
            read_bank <= 1'b0;
            read_index <= 10'd0;
            read_count <= 16'd0;
            read_word <= 32'd0;
            read_valid_pulse <= 1'b0;
            raw_block_ready_pulse <= 1'b0;
            underflow_pulse <= 1'b0;
        end else begin
            read_valid_pulse <= 1'b0;
            raw_block_ready_pulse <= 1'b0;
            underflow_pulse <= 1'b0;

            if (clear_fifo) begin
                read_armed <= 1'b0;
                active_ch_enable <= 2'b00;
                read_bank <= 1'b0;
                read_index <= 10'd0;
                read_count <= 16'd0;
            end

            if (frame_ready_pulse) begin
                read_armed <= raw_enable && (|ch_enable);
                active_ch_enable <= ch_enable;
                read_bank <= ch_enable[0] ? 1'b0 : 1'b1;
                read_index <= 10'd0;
                read_count <= 16'd0;
            end

            if (read_pop) begin
                if (!read_armed || !raw_enable) begin
                    underflow_pulse <= 1'b1;
                end else begin
                    read_word <= {read_count[11:0], read_bank, frame_end, 1'b1, 1'b0, selected_sample, 4'h0};
                    read_valid_pulse <= 1'b1;

                    if (frame_end) begin
                        if (read_bank == 1'b0 && active_ch_enable[1]) begin
                            read_bank <= 1'b1;
                            read_index <= 10'd0;
                            read_count <= 16'd0;
                        end else begin
                            read_armed <= 1'b0;
                            read_bank <= 1'b0;
                            read_index <= 10'd0;
                            read_count <= 16'd0;
                            raw_block_ready_pulse <= 1'b1;
                        end
                    end else begin
                        read_count <= read_count + 1'b1;
                        read_index <= read_count[9:0] + 1'b1;
                    end
                end
            end
        end
    end

endmodule
