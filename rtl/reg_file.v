module reg_file(
    input         clk,
    input         rst_n,

    input         wr_en,
    input  [1:0]  wr_target,
    input  [4:0]  wr_addr,
    input  [31:0] wr_data,

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
    output [31:0] ch_b_phase_init
);

    localparam [1:0] TARGET_CHA    = 2'b00;
    localparam [1:0] TARGET_CHB    = 2'b01;
    localparam [1:0] TARGET_GLOBAL = 2'b10;

    localparam [4:0] REG_CTRL       = 5'h00;
    localparam [4:0] REG_FREQ_WORD  = 5'h01;
    localparam [4:0] REG_PHASE_INIT = 5'h02;
    localparam [4:0] REG_AMP_SCALE  = 5'h03;
    localparam [4:0] REG_DC_OFFSET  = 5'h04;

    localparam [4:0] REG_GLOBAL_CTRL = 5'h00;
    localparam [4:0] REG_VERSION     = 5'h01;
    localparam [4:0] REG_STATUS      = 5'h02;

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
        end else if (wr_en) begin
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

                default: begin
                    global_ctrl <= global_ctrl;
                end
            endcase
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

            default: begin
                rd_data = 32'd0;
            end
        endcase
    end

endmodule

