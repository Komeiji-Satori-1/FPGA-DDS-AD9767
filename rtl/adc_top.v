module adc_top(
    input         sys_clk,
    input         rst_n,
    input         acq_enable,
    input         one_shot,
    input         irq_enable,
    input         raw_enable,
    input         fft_enable,
    input         soft_reset_pulse,
    input         clear_fifo_pulse,
    input         read_pop,
    input  [1:0]  ch_enable,
    input  [15:0] sample_div,
    input  [15:0] frame_len,
    input  [31:0] read_mode,
    input  [31:0] irq_mask,
    input  [31:0] fft_ctrl,
    input  [31:0] irq_status_clear,
    input  [31:0] error_status_clear,
    input  [11:0] ad1_data,
    input  [11:0] ad2_data,
    output        AD_1_CLK,
    output        AD_2_CLK,
    output        irq,
    output [31:0] irq_status,
    output [31:0] error_status,
    output [31:0] buffer_level,
    output [31:0] sample_count,
    output [31:0] fft_status,
    output [31:0] read_word
);

    wire adc_clk;
    wire sample_tick;
    wire wr_en_ch1;
    wire wr_en_ch2;
    wire [9:0] wr_addr;
    wire frame_ready_pulse;
    wire overflow_pulse;
    wire [15:0] capture_sample_count;
    wire [11:0] mem_rd_ch1;
    wire [11:0] mem_rd_ch2;
    wire read_bank;
    wire [9:0] read_index;
    wire [31:0] read_word_int;
    wire read_valid_pulse;
    wire raw_block_ready_pulse;
    wire underflow_pulse;
    wire config_error_pulse;
    wire adc_misaligned_pulse;

    assign AD_1_CLK = adc_clk;
    assign AD_2_CLK = adc_clk;
    assign buffer_level = {16'd0, capture_sample_count};
    assign sample_count = {16'd0, capture_sample_count};
    assign fft_status = 32'd0;
    assign read_word = read_word_int;
    assign config_error_pulse = 1'b0;
    assign adc_misaligned_pulse = 1'b0;

    adc_clk_gen adc_clk_gen_inst(
        .clk(sys_clk),
        .rst_n(rst_n),
        .enable(acq_enable),
        .half_period(sample_div),
        .adc_clk(adc_clk),
        .sample_tick(sample_tick)
    );

    adc_capture adc_capture_inst(
        .clk(sys_clk),
        .rst_n(rst_n),
        .sample_tick(sample_tick),
        .acq_enable(acq_enable),
        .one_shot(one_shot),
        .clear_fifo(clear_fifo_pulse | soft_reset_pulse),
        .ch1_enable(ch_enable[0]),
        .ch2_enable(ch_enable[1]),
        .frame_len(frame_len),
        .ad1_data(ad1_data),
        .ad2_data(ad2_data),
        .wr_en_ch1(wr_en_ch1),
        .wr_en_ch2(wr_en_ch2),
        .wr_addr(wr_addr),
        .frame_ready_pulse(frame_ready_pulse),
        .overflow_pulse(overflow_pulse),
        .sample_count(capture_sample_count)
    );

    adc_frame_buffer adc_frame_buffer_inst(
        .wr_clk(sys_clk),
        .wr_en_ch1(wr_en_ch1),
        .wr_en_ch2(wr_en_ch2),
        .wr_addr(wr_addr),
        .wr_data_ch1(ad1_data),
        .wr_data_ch2(ad2_data),
        .rd_addr(read_index),
        .rd_data_ch1(mem_rd_ch1),
        .rd_data_ch2(mem_rd_ch2)
    );

    adc_readout adc_readout_inst(
        .clk(sys_clk),
        .rst_n(rst_n),
        .clear_fifo(clear_fifo_pulse | soft_reset_pulse),
        .frame_ready_pulse(frame_ready_pulse),
        .read_pop(read_pop),
        .raw_enable(raw_enable),
        .ch_enable(ch_enable),
        .frame_len(frame_len),
        .rd_data_ch1(mem_rd_ch1),
        .rd_data_ch2(mem_rd_ch2),
        .read_bank(read_bank),
        .read_index(read_index),
        .read_word(read_word_int),
        .read_valid_pulse(read_valid_pulse),
        .raw_block_ready_pulse(raw_block_ready_pulse),
        .underflow_pulse(underflow_pulse)
    );

    adc_irq adc_irq_inst(
        .clk(sys_clk),
        .rst_n(rst_n),
        .frame_ready_pulse(frame_ready_pulse),
        .raw_block_ready_pulse(raw_block_ready_pulse),
        .overflow_pulse(overflow_pulse),
        .underflow_pulse(underflow_pulse),
        .config_error_pulse(config_error_pulse),
        .adc_misaligned_pulse(adc_misaligned_pulse),
        .irq_enable(irq_enable),
        .irq_mask(irq_mask),
        .irq_status_clear(irq_status_clear),
        .error_status_clear(error_status_clear),
        .irq(irq),
        .irq_status(irq_status),
        .error_status(error_status)
    );

endmodule
