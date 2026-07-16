module adc_irq(
    input         clk,
    input         rst_n,
    input         frame_ready_pulse,
    input         raw_block_ready_pulse,
    input         overflow_pulse,
    input         underflow_pulse,
    input         config_error_pulse,
    input         adc_misaligned_pulse,
    input         irq_enable,
    input  [31:0] irq_mask,
    input  [31:0] irq_status_clear,
    input  [31:0] error_status_clear,
    output reg    irq,
    output reg [31:0] irq_status,
    output reg [31:0] error_status
);

    reg [31:0] irq_status_next;
    reg [31:0] error_status_next;

    wire irq_pending;

    assign irq_pending = |((irq_status_next[7:0]) & (~irq_mask[7:0]));

    always @(*) begin
        irq_status_next = irq_status;
        error_status_next = error_status;

        irq_status_next = irq_status_next & ~irq_status_clear;
        error_status_next = error_status_next & ~error_status_clear;

        if (frame_ready_pulse)
            irq_status_next[0] = 1'b1;
        if (raw_block_ready_pulse)
            irq_status_next[1] = 1'b1;
        if (overflow_pulse) begin
            irq_status_next[3] = 1'b1;
            error_status_next[0] = 1'b1;
        end
        if (underflow_pulse) begin
            irq_status_next[4] = 1'b1;
            error_status_next[1] = 1'b1;
        end
        if (config_error_pulse) begin
            irq_status_next[5] = 1'b1;
            error_status_next[4] = 1'b1;
        end
        if (adc_misaligned_pulse) begin
            irq_status_next[6] = 1'b1;
            error_status_next[3] = 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_status <= 32'd0;
            error_status <= 32'd0;
            irq <= 1'b0;
        end else begin
            irq_status <= irq_status_next;
            error_status <= error_status_next;
            irq <= irq_enable && irq_pending;
        end
    end

endmodule
