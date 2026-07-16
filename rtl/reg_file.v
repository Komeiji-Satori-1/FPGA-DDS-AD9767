module reg_file(
    input         clk,
    input         rst_n,

    input         wr_en,
    input  [1:0]  wr_target,
    input  [4:0]  wr_addr,
    input  [31:0] wr_data,

    input         rd_en,
    input         rd_commit,
    input  [1:0]  rd_target,
    input  [4:0]  rd_addr,
    output reg [31:0] rd_data,

    output        global_enable,
    output        key_ctrl_enable,

    output        ch_a_enable,
    output [1:0]  ch_a_wave_sel,
    output        ch_a_phase_reset,
    output [31:0] ch_a_fword,
    output [31:0] ch_a_phase_init,

    output        ch_b_enable,
    output [1:0]  ch_b_wave_sel,
    output        ch_b_phase_reset,
    output [31:0] ch_b_fword,
    output [31:0] ch_b_phase_init,

    output        adc_acq_enable,
    output        adc_one_shot,
    output        adc_irq_enable,
    output        adc_raw_enable,
    output        adc_fft_enable,
    output        adc_soft_reset_pulse,
    output        adc_clear_fifo_pulse,
    output [1:0]  adc_ch_enable,
    output [15:0] adc_sample_div,
    output [15:0] adc_frame_len,
    output [31:0] adc_read_mode,
    output [31:0] adc_irq_mask,
    output [31:0] adc_fft_ctrl,
    output        adc_read_pop,
    output [31:0] adc_irq_status_clear,
    output [31:0] adc_error_status_clear,

    input  [31:0] adc_irq_status,
    input  [31:0] adc_error_status,
    input  [31:0] adc_buffer_level,
    input  [31:0] adc_sample_count,
    input  [31:0] adc_fft_status,
    input  [31:0] adc_read_word
);

    localparam [1:0] TARGET_CHA    = 2'b00;
    localparam [1:0] TARGET_CHB    = 2'b01;
    localparam [1:0] TARGET_GLOBAL = 2'b10;
    localparam [1:0] TARGET_ADC    = 2'b11;

    localparam [4:0] REG_CTRL       = 5'h00;
    localparam [4:0] REG_FREQ_WORD  = 5'h01;
    localparam [4:0] REG_PHASE_INIT = 5'h02;
    localparam [4:0] REG_AMP_SCALE  = 5'h03;
    localparam [4:0] REG_DC_OFFSET  = 5'h04;

    localparam [4:0] REG_GLOBAL_CTRL = 5'h00;
    localparam [4:0] REG_VERSION     = 5'h01;
    localparam [4:0] REG_STATUS      = 5'h02;

    localparam [4:0] REG_ACQ_CTRL        = 5'h00;
    localparam [4:0] REG_ADC_CH_ENABLE    = 5'h01;
    localparam [4:0] REG_SAMPLE_CFG      = 5'h02;
    localparam [4:0] REG_FRAME_LEN       = 5'h03;
    localparam [4:0] REG_READ_MODE       = 5'h04;
    localparam [4:0] REG_IRQ_MASK        = 5'h05;
    localparam [4:0] REG_IRQ_STATUS      = 5'h06;
    localparam [4:0] REG_ERROR_STATUS    = 5'h07;
    localparam [4:0] REG_BUFFER_LEVEL    = 5'h08;
    localparam [4:0] REG_SAMPLE_COUNT    = 5'h09;
    localparam [4:0] REG_FFT_CTRL        = 5'h0A;
    localparam [4:0] REG_FFT_STATUS      = 5'h0B;
    localparam [4:0] REG_READ_DATA       = 5'h0C;

    localparam [31:0] VERSION_VALUE = 32'h0001_0000;

    reg [31:0] global_ctrl;
    reg [31:0] status_reg;

    reg [31:0] ch_a_ctrl;
    reg [31:0] ch_a_freq_word;
    reg [31:0] ch_a_phase_init_reg;
    reg [31:0] ch_a_amp_scale;
    reg [31:0] ch_a_dc_offset;

    reg [31:0] ch_b_ctrl;
    reg [31:0] ch_b_freq_word;
    reg [31:0] ch_b_phase_init_reg;
    reg [31:0] ch_b_amp_scale;
    reg [31:0] ch_b_dc_offset;

    reg [31:0] adc_acq_ctrl_reg;
    reg [31:0] adc_ch_enable_reg;
    reg [31:0] adc_sample_cfg_reg;
    reg [31:0] adc_frame_len_reg;
    reg [31:0] adc_read_mode_reg;
    reg [31:0] adc_irq_mask_reg;
    reg [31:0] adc_fft_ctrl_reg;

    reg        adc_soft_reset_pulse_r;
    reg        adc_clear_fifo_pulse_r;
    reg [31:0] adc_irq_status_clear_r;
    reg [31:0] adc_error_status_clear_r;
    reg        adc_read_pop_r;

    assign global_enable = global_ctrl[0];
    assign key_ctrl_enable = global_ctrl[2];

    assign ch_a_enable = ch_a_ctrl[0];
    assign ch_a_wave_sel = ch_a_ctrl[2:1];
    assign ch_a_phase_reset = ch_a_ctrl[3];
    assign ch_a_fword = ch_a_freq_word;
    assign ch_a_phase_init = ch_a_phase_init_reg;

    assign ch_b_enable = ch_b_ctrl[0];
    assign ch_b_wave_sel = ch_b_ctrl[2:1];
    assign ch_b_phase_reset = ch_b_ctrl[3];
    assign ch_b_fword = ch_b_freq_word;
    assign ch_b_phase_init = ch_b_phase_init_reg;

    assign adc_acq_enable = adc_acq_ctrl_reg[0];
    assign adc_one_shot = adc_acq_ctrl_reg[1];
    assign adc_irq_enable = adc_acq_ctrl_reg[4];
    assign adc_raw_enable = adc_acq_ctrl_reg[6];
    assign adc_fft_enable = adc_acq_ctrl_reg[7];
    assign adc_ch_enable = adc_ch_enable_reg[1:0];
    assign adc_sample_div = adc_sample_cfg_reg[15:0];
    assign adc_frame_len = adc_frame_len_reg[15:0];
    assign adc_read_mode = adc_read_mode_reg;
    assign adc_irq_mask = adc_irq_mask_reg;
    assign adc_fft_ctrl = adc_fft_ctrl_reg;
    assign adc_soft_reset_pulse = adc_soft_reset_pulse_r;
    assign adc_clear_fifo_pulse = adc_clear_fifo_pulse_r;
    assign adc_irq_status_clear = adc_irq_status_clear_r;
    assign adc_error_status_clear = adc_error_status_clear_r;
    assign adc_read_pop = adc_read_pop_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            global_ctrl <= 32'd0;
            status_reg <= 32'd0;

            ch_a_ctrl <= 32'd0;
            ch_a_freq_word <= 32'd0;
            ch_a_phase_init_reg <= 32'd0;
            ch_a_amp_scale <= 32'h0000_3fff;
            ch_a_dc_offset <= 32'h0000_2000;

            ch_b_ctrl <= 32'd0;
            ch_b_freq_word <= 32'd0;
            ch_b_phase_init_reg <= 32'd0;
            ch_b_amp_scale <= 32'h0000_3fff;
            ch_b_dc_offset <= 32'h0000_2000;

            adc_acq_ctrl_reg <= 32'd0;
            adc_ch_enable_reg <= 32'h0000_0003;
            adc_sample_cfg_reg <= 32'd25;
            adc_frame_len_reg <= 32'h0000_0400;
            adc_read_mode_reg <= 32'h0000_0001;
            adc_irq_mask_reg <= 32'h0000_0000;
            adc_fft_ctrl_reg <= 32'd0;

            adc_soft_reset_pulse_r <= 1'b0;
            adc_clear_fifo_pulse_r <= 1'b0;
            adc_irq_status_clear_r <= 32'd0;
            adc_error_status_clear_r <= 32'd0;
            adc_read_pop_r <= 1'b0;
        end else begin
            adc_soft_reset_pulse_r <= 1'b0;
            adc_clear_fifo_pulse_r <= 1'b0;
            adc_irq_status_clear_r <= 32'd0;
            adc_error_status_clear_r <= 32'd0;
            adc_read_pop_r <= 1'b0;

            if (wr_en) begin
                case (wr_target)
                    TARGET_CHA: begin
                        case (wr_addr)
                            REG_CTRL:       ch_a_ctrl <= wr_data;
                            REG_FREQ_WORD:  ch_a_freq_word <= wr_data;
                            REG_PHASE_INIT: ch_a_phase_init_reg <= wr_data;
                            REG_AMP_SCALE:  ch_a_amp_scale <= wr_data;
                            REG_DC_OFFSET:  ch_a_dc_offset <= wr_data;
                            default:        ch_a_ctrl <= ch_a_ctrl;
                        endcase
                    end

                    TARGET_CHB: begin
                        case (wr_addr)
                            REG_CTRL:       ch_b_ctrl <= wr_data;
                            REG_FREQ_WORD:  ch_b_freq_word <= wr_data;
                            REG_PHASE_INIT: ch_b_phase_init_reg <= wr_data;
                            REG_AMP_SCALE:  ch_b_amp_scale <= wr_data;
                            REG_DC_OFFSET:  ch_b_dc_offset <= wr_data;
                            default:        ch_b_ctrl <= ch_b_ctrl;
                        endcase
                    end

                    TARGET_GLOBAL: begin
                        case (wr_addr)
                            REG_GLOBAL_CTRL: global_ctrl <= wr_data;
                            REG_STATUS:      status_reg <= wr_data;
                            default:         global_ctrl <= global_ctrl;
                        endcase
                    end

                    TARGET_ADC: begin
                        case (wr_addr)
                            REG_ACQ_CTRL: begin
                                adc_acq_ctrl_reg <= wr_data & 32'hfffffff3;
                                adc_soft_reset_pulse_r <= wr_data[2];
                                adc_clear_fifo_pulse_r <= wr_data[3];
                            end

                            REG_ADC_CH_ENABLE: adc_ch_enable_reg <= wr_data;
                            REG_SAMPLE_CFG:    adc_sample_cfg_reg <= wr_data;
                            REG_FRAME_LEN:     adc_frame_len_reg <= wr_data;
                            REG_READ_MODE:     adc_read_mode_reg <= wr_data;
                            REG_IRQ_MASK:      adc_irq_mask_reg <= wr_data;
                            REG_IRQ_STATUS:    adc_irq_status_clear_r <= wr_data;
                            REG_ERROR_STATUS:  adc_error_status_clear_r <= wr_data;
                            REG_FFT_CTRL:      adc_fft_ctrl_reg <= wr_data;
                            default:           adc_acq_ctrl_reg <= adc_acq_ctrl_reg;
                        endcase
                    end

                    default: begin
                        global_ctrl <= global_ctrl;
                    end
                endcase
            end

            if (rd_commit && rd_target == TARGET_ADC && rd_addr == REG_READ_DATA)
                adc_read_pop_r <= 1'b1;
        end
    end

    always @(*) begin
        case (rd_target)
            TARGET_CHA: begin
                case (rd_addr)
                    REG_CTRL:       rd_data = ch_a_ctrl;
                    REG_FREQ_WORD:  rd_data = ch_a_freq_word;
                    REG_PHASE_INIT: rd_data = ch_a_phase_init_reg;
                    REG_AMP_SCALE:  rd_data = ch_a_amp_scale;
                    REG_DC_OFFSET:  rd_data = ch_a_dc_offset;
                    default:        rd_data = 32'd0;
                endcase
            end

            TARGET_CHB: begin
                case (rd_addr)
                    REG_CTRL:       rd_data = ch_b_ctrl;
                    REG_FREQ_WORD:  rd_data = ch_b_freq_word;
                    REG_PHASE_INIT: rd_data = ch_b_phase_init_reg;
                    REG_AMP_SCALE:  rd_data = ch_b_amp_scale;
                    REG_DC_OFFSET:  rd_data = ch_b_dc_offset;
                    default:        rd_data = 32'd0;
                endcase
            end

            TARGET_GLOBAL: begin
                case (rd_addr)
                    REG_GLOBAL_CTRL: rd_data = global_ctrl;
                    REG_VERSION:     rd_data = VERSION_VALUE;
                    REG_STATUS:      rd_data = status_reg;
                    default:         rd_data = 32'd0;
                endcase
            end

            TARGET_ADC: begin
                case (rd_addr)
                    REG_ACQ_CTRL:     rd_data = adc_acq_ctrl_reg;
                    REG_ADC_CH_ENABLE:rd_data = adc_ch_enable_reg;
                    REG_SAMPLE_CFG:   rd_data = adc_sample_cfg_reg;
                    REG_FRAME_LEN:    rd_data = adc_frame_len_reg;
                    REG_READ_MODE:    rd_data = adc_read_mode_reg;
                    REG_IRQ_MASK:     rd_data = adc_irq_mask_reg;
                    REG_IRQ_STATUS:   rd_data = adc_irq_status;
                    REG_ERROR_STATUS: rd_data = adc_error_status;
                    REG_BUFFER_LEVEL: rd_data = adc_buffer_level;
                    REG_SAMPLE_COUNT: rd_data = adc_sample_count;
                    REG_FFT_CTRL:     rd_data = adc_fft_ctrl_reg;
                    REG_FFT_STATUS:   rd_data = adc_fft_status;
                    REG_READ_DATA:    rd_data = adc_read_word;
                    default:          rd_data = 32'd0;
                endcase
            end

            default: begin
                rd_data = 32'd0;
            end
        endcase
    end

endmodule
