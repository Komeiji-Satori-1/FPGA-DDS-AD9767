module key_ctrl(
    input         clk,
    input         rst_n,
    input         enable,
    input         key_in,
    output reg [31:0] debug_fword,
    output reg [3:0]  debug_index
);

    localparam integer DEBOUNCE_MAX = 20'd999999;

    reg        key_sync_0;
    reg        key_sync_1;
    reg        key_state;
    reg [19:0] debounce_cnt;
    reg        key_pressed_d;

    wire key_pressed;

    assign key_pressed = !key_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_sync_0 <= 1'b1;
            key_sync_1 <= 1'b1;
        end else begin
            key_sync_0 <= key_in;
            key_sync_1 <= key_sync_0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_state <= 1'b1;
            debounce_cnt <= 20'd0;
        end else if (key_sync_1 == key_state) begin
            debounce_cnt <= 20'd0;
        end else if (debounce_cnt == DEBOUNCE_MAX) begin
            key_state <= key_sync_1;
            debounce_cnt <= 20'd0;
        end else begin
            debounce_cnt <= debounce_cnt + 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            key_pressed_d <= 1'b0;
        else
            key_pressed_d <= key_pressed;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            debug_index <= 4'd0;
        else if (enable && key_pressed && !key_pressed_d)
            debug_index <= debug_index + 1'b1;
        else
            debug_index <= debug_index;
    end

    always @(*) begin
        case (debug_index)
            4'd0:  debug_fword = 32'd429;       // 10 Hz at 100 MHz DDS clock
            4'd1:  debug_fword = 32'd2147;      // 50 Hz
            4'd2:  debug_fword = 32'd4295;      // 100 Hz
            4'd3:  debug_fword = 32'd21475;     // 500 Hz
            4'd4:  debug_fword = 32'd42950;     // 1 kHz
            4'd5:  debug_fword = 32'd214748;    // 5 kHz
            4'd6:  debug_fword = 32'd429497;    // 10 kHz
            4'd7:  debug_fword = 32'd2147484;   // 50 kHz
            4'd8:  debug_fword = 32'd4294967;   // 100 kHz
            4'd9:  debug_fword = 32'd21474836;  // 500 kHz
            4'd10: debug_fword = 32'd42949673;  // 1 MHz
            4'd11: debug_fword = 32'd85899346;  // 2 MHz
            4'd12: debug_fword = 32'd128849019; // 3 MHz
            4'd13: debug_fword = 32'd171798692; // 4 MHz
            4'd14: debug_fword = 32'd214748365; // 5 MHz
            4'd15: debug_fword = 32'd429496730; // 10 MHz
            default: debug_fword = 32'd429497;
        endcase
    end

endmodule

