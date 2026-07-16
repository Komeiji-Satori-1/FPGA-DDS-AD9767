module spi_slave(
    input         sys_clk,
    input         rst_n,

    input         spi_sclk,
    input         spi_mosi,
    output reg    spi_miso,
    input         spi_cs_n,

    output [1:0]  rd_target,
    output [4:0]  rd_addr,
    input  [31:0] rd_data,
    output reg    rd_en,
    output reg    rd_commit,

    output reg    wr_en,
    output reg [1:0]  wr_target,
    output reg [4:0]  wr_addr,
    output reg [31:0] wr_data,
    output reg    frame_error
);

    reg [5:0]  bit_count;
    reg [7:0]  cmd_shift;
    reg [7:0]  cmd_reg;
    reg [31:0] data_shift_in;
    reg [31:0] data_shift_out;

    reg        wr_toggle_spi;
    reg        rd_toggle_spi;
    reg        rd_commit_toggle_spi;
    reg        rd_pending_spi;
    reg [1:0]  wr_target_spi;
    reg [4:0]  wr_addr_spi;
    reg [31:0] wr_data_spi;
    reg        frame_error_spi;

    reg [2:0] wr_toggle_sync;
    reg [2:0] rd_toggle_sync;
    reg [2:0] rd_commit_sync;

    wire [7:0] cmd_next;
    wire       cmd_is_write;

    assign cmd_next = {cmd_shift[6:0], spi_mosi};
    assign cmd_is_write = (cmd_reg[7] == 1'b0);
    assign rd_target = cmd_reg[6:5];
    assign rd_addr = cmd_reg[4:0];

    always @(posedge spi_sclk or posedge spi_cs_n or negedge rst_n) begin
        if (!rst_n) begin
            bit_count <= 6'd0;
            cmd_shift <= 8'd0;
            cmd_reg <= 8'd0;
            data_shift_in <= 32'd0;
            wr_toggle_spi <= 1'b0;
            wr_target_spi <= 2'd0;
            wr_addr_spi <= 5'd0;
            wr_data_spi <= 32'd0;
            frame_error_spi <= 1'b0;
            rd_toggle_spi <= 1'b0;
            rd_commit_toggle_spi <= 1'b0;
            rd_pending_spi <= 1'b0;
        end else if (spi_cs_n) begin
            if (bit_count != 6'd0 && bit_count != 6'd40)
                frame_error_spi <= 1'b1;
            if (rd_pending_spi && bit_count == 6'd40)
                rd_commit_toggle_spi <= !rd_commit_toggle_spi;
            bit_count <= 6'd0;
            cmd_shift <= 8'd0;
            data_shift_in <= 32'd0;
            rd_pending_spi <= 1'b0;
        end else begin
            if (bit_count < 6'd8)
                cmd_shift <= cmd_next;

            if (bit_count == 6'd7)
                cmd_reg <= cmd_next;

            if (bit_count >= 6'd8 && bit_count < 6'd40)
                data_shift_in <= {data_shift_in[30:0], spi_mosi};

            if (bit_count == 6'd39) begin
                if (cmd_is_write) begin
                    wr_target_spi <= cmd_reg[6:5];
                    wr_addr_spi <= cmd_reg[4:0];
                    wr_data_spi <= {data_shift_in[30:0], spi_mosi};
                    wr_toggle_spi <= !wr_toggle_spi;
                end
            end

            if (bit_count == 6'd8 && !cmd_is_write)
                rd_toggle_spi <= !rd_toggle_spi;

            if (bit_count == 6'd8 && !cmd_is_write)
                rd_pending_spi <= 1'b1;

            if (bit_count < 6'd40)
                bit_count <= bit_count + 1'b1;
            else
                frame_error_spi <= 1'b1;
        end
    end

    always @(negedge spi_sclk or posedge spi_cs_n or negedge rst_n) begin
        if (!rst_n) begin
            spi_miso <= 1'b0;
            data_shift_out <= 32'd0;
        end else if (spi_cs_n) begin
            spi_miso <= 1'b0;
            data_shift_out <= 32'd0;
        end else if (bit_count == 6'd8) begin
            data_shift_out <= {rd_data[30:0], 1'b0};
            spi_miso <= rd_data[31];
        end else if (bit_count > 6'd8 && bit_count <= 6'd40) begin
            spi_miso <= data_shift_out[31];
            data_shift_out <= {data_shift_out[30:0], 1'b0};
        end else begin
            spi_miso <= 1'b0;
        end
    end

    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_toggle_sync <= 3'b000;
            rd_toggle_sync <= 3'b000;
            rd_commit_sync <= 3'b000;
            wr_en <= 1'b0;
            rd_en <= 1'b0;
            rd_commit <= 1'b0;
            wr_target <= 2'd0;
            wr_addr <= 5'd0;
            wr_data <= 32'd0;
            frame_error <= 1'b0;
        end else begin
            wr_toggle_sync <= {wr_toggle_sync[1:0], wr_toggle_spi};
            wr_en <= wr_toggle_sync[2] ^ wr_toggle_sync[1];

            rd_toggle_sync <= {rd_toggle_sync[1:0], rd_toggle_spi};
            rd_en <= rd_toggle_sync[2] ^ rd_toggle_sync[1];

            rd_commit_sync <= {rd_commit_sync[1:0], rd_commit_toggle_spi};
            rd_commit <= rd_commit_sync[2] ^ rd_commit_sync[1];

            if (wr_toggle_sync[2] ^ wr_toggle_sync[1]) begin
                wr_target <= wr_target_spi;
                wr_addr <= wr_addr_spi;
                wr_data <= wr_data_spi;
            end

            frame_error <= frame_error_spi;
        end
    end

endmodule
