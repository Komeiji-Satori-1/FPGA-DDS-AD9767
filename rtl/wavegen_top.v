module wavegen(
    input         CLK50M,
    input         Rst_n,
    input         Key,

    input         SPI_SCLK,
    input         SPI_MOSI,
    output        SPI_MISO,
    input         SPI_CS_N,

    output        DACA_CLK,
    output        DACB_CLK,
    output        DACA_WRT,
    output        DACB_WRT,
    output [13:0] DACA_DATA,
    output [13:0] DACB_DATA
);

    wire sys_clk;
    wire dac_clk;
    wire rst_n_sync;

    wire [1:0] spi_rd_target;
    wire [4:0] spi_rd_addr;
    wire [31:0] spi_rd_data;

    wire spi_wr_en;
    wire [1:0] spi_wr_target;
    wire [4:0] spi_wr_addr;
    wire [31:0] spi_wr_data;
    wire spi_frame_error;

    wire global_enable;
    wire key_ctrl_enable;

    wire ch_a_enable;
    wire [1:0] ch_a_wave_sel;
    wire ch_a_phase_reset;
    wire [31:0] ch_a_fword;
    wire [31:0] ch_a_phase_init;

    wire ch_b_enable;
    wire [1:0] ch_b_wave_sel;
    wire ch_b_phase_reset;
    wire [31:0] ch_b_fword;
    wire [31:0] ch_b_phase_init;

    wire [31:0] key_debug_fword;
    wire [3:0]  key_debug_index;
    wire [31:0] ch_a_fword_eff;

    wire [13:0] ch_a_wave_data;
    wire [13:0] ch_b_wave_data;

    assign sys_clk = CLK50M;
    assign dac_clk = CLK50M;
    assign ch_a_fword_eff = key_ctrl_enable ? key_debug_fword : ch_a_fword;

    reset_sync reset_sync_inst(
        .clk(sys_clk),
        .rst_n_async(Rst_n),
        .rst_n_sync(rst_n_sync)
    );

    spi_slave spi_slave_inst(
        .sys_clk(sys_clk),
        .rst_n(rst_n_sync),
        .spi_sclk(SPI_SCLK),
        .spi_mosi(SPI_MOSI),
        .spi_miso(SPI_MISO),
        .spi_cs_n(SPI_CS_N),
        .rd_target(spi_rd_target),
        .rd_addr(spi_rd_addr),
        .rd_data(spi_rd_data),
        .wr_en(spi_wr_en),
        .wr_target(spi_wr_target),
        .wr_addr(spi_wr_addr),
        .wr_data(spi_wr_data),
        .frame_error(spi_frame_error)
    );

    reg_file reg_file_inst(
        .clk(sys_clk),
        .rst_n(rst_n_sync),
        .wr_en(spi_wr_en),
        .wr_target(spi_wr_target),
        .wr_addr(spi_wr_addr),
        .wr_data(spi_wr_data),
        .rd_target(spi_rd_target),
        .rd_addr(spi_rd_addr),
        .rd_data(spi_rd_data),
        .global_enable(global_enable),
        .key_ctrl_enable(key_ctrl_enable),
        .ch_a_enable(ch_a_enable),
        .ch_a_wave_sel(ch_a_wave_sel),
        .ch_a_phase_reset(ch_a_phase_reset),
        .ch_a_fword(ch_a_fword),
        .ch_a_phase_init(ch_a_phase_init),
        .ch_b_enable(ch_b_enable),
        .ch_b_wave_sel(ch_b_wave_sel),
        .ch_b_phase_reset(ch_b_phase_reset),
        .ch_b_fword(ch_b_fword),
        .ch_b_phase_init(ch_b_phase_init)
    );

    key_ctrl key_ctrl_inst(
        .clk(sys_clk),
        .rst_n(rst_n_sync),
        .enable(key_ctrl_enable),
        .key_in(Key),
        .debug_fword(key_debug_fword),
        .debug_index(key_debug_index)
    );

    dds_channel dds_channel_a(
        .clk(dac_clk),
        .rst_n(rst_n_sync),
        .enable(ch_a_enable),
        .phase_reset(ch_a_phase_reset),
        .fword(ch_a_fword_eff),
        .phase_init(ch_a_phase_init),
        .wave_sel(ch_a_wave_sel),
        .wave_data(ch_a_wave_data)
    );

    dds_channel dds_channel_b(
        .clk(dac_clk),
        .rst_n(rst_n_sync),
        .enable(ch_b_enable),
        .phase_reset(ch_b_phase_reset),
        .fword(ch_b_fword),
        .phase_init(ch_b_phase_init),
        .wave_sel(ch_b_wave_sel),
        .wave_data(ch_b_wave_data)
    );

    dac_ad9767_if dac_ad9767_if_inst(
        .dac_clk(dac_clk),
        .rst_n(rst_n_sync),
        .global_enable(global_enable),
        .ch_a_data(ch_a_wave_data),
        .ch_b_data(ch_b_wave_data),
        .DACA_CLK(DACA_CLK),
        .DACB_CLK(DACB_CLK),
        .DACA_WRT(DACA_WRT),
        .DACB_WRT(DACB_WRT),
        .DACA_DATA(DACA_DATA),
        .DACB_DATA(DACB_DATA)
    );

endmodule

