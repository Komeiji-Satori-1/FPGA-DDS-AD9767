module dds_channel(
    input         clk,
    input         rst_n,
    input         enable,
    input         phase_reset,
    input  [31:0] fword,
    input  [31:0] phase_init,
    input  [1:0]  wave_sel,
    output [13:0] wave_data
);

    localparam [1:0] WAVE_SINE     = 2'b00;
    localparam [1:0] WAVE_SQUARE   = 2'b01;
    localparam [1:0] WAVE_TRIANGLE = 2'b10;

    reg [31:0] phase_acc;

    wire [31:0] phase_next;
    wire [31:0] phase_now;
    wire [13:0] sine_data;
    wire [13:0] square_data;
    wire [13:0] triangle_data;
    reg  [13:0] selected_data;

    assign phase_next = phase_acc + fword;
    assign phase_now = phase_acc + phase_init;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            phase_acc <= 32'd0;
        else if (phase_reset)
            phase_acc <= 32'd0;
        else if (enable)
            phase_acc <= phase_next;
        else
            phase_acc <= phase_acc;
    end

    wave_sine_lut wave_sine_lut_inst(
        .clk(clk),
        .addr(phase_now[31:18]),
        .data(sine_data)
    );

    wave_square wave_square_inst(
        .phase(phase_now),
        .wave_data(square_data)
    );

    wave_triangle wave_triangle_inst(
        .phase(phase_now),
        .wave_data(triangle_data)
    );

    always @(*) begin
        case (wave_sel)
            WAVE_SINE:     selected_data = sine_data;
            WAVE_SQUARE:   selected_data = square_data;
            WAVE_TRIANGLE: selected_data = triangle_data;
            default:       selected_data = 14'h2000;
        endcase
    end

    assign wave_data = enable ? selected_data : 14'h2000;

endmodule

