//SystemVerilog
module DualModeIVMU #(
    parameter DIRECT_BASE = 32'hB000_0000,
    parameter VECTOR_BASE = 32'hB100_0000
)(
    input wire clk,
    input wire rst_n,
    input wire [7:0] interrupt,
    input wire mode_sel, // 0=direct, 1=vectored
    input wire irq_ack,
    output reg [31:0] isr_addr,
    output reg irq_active
);
    reg [7:0] irq_status;
    wire [7:0] pending_irqs;
    reg [2:0] selected_irq;
    wire has_pending_irq;

    // Precompute new pending IRQs and if any are present
    assign pending_irqs = interrupt & ~irq_status;
    assign has_pending_irq = |pending_irqs;

    // Balanced priority encoder for the highest pending IRQ (7 = highest)
    wire [3:0] upper_nibble = pending_irqs[7:4];
    wire [3:0] lower_nibble = pending_irqs[3:0];

    wire upper_nonzero = |upper_nibble;
    wire lower_nonzero = |lower_nibble;

    reg [1:0] upper_priority;
    reg [1:0] lower_priority;

    always @(*) begin
        casez (upper_nibble)
            4'b1???: upper_priority = 2'd3;
            4'b01??: upper_priority = 2'd2;
            4'b001?: upper_priority = 2'd1;
            4'b0001: upper_priority = 2'd0;
            default: upper_priority = 2'd0;
        endcase
    end

    always @(*) begin
        casez (lower_nibble)
            4'b1???: lower_priority = 2'd3;
            4'b01??: lower_priority = 2'd2;
            4'b001?: lower_priority = 2'd1;
            4'b0001: lower_priority = 2'd0;
            default: lower_priority = 2'd0;
        endcase
    end

    always @(*) begin
        if (upper_nonzero)
            selected_irq = {2'b11,1'b0} - {1'b0, upper_priority}; // 7..4
        else if (lower_nonzero)
            selected_irq = {2'b01,1'b0} - {1'b0, lower_priority}; // 3..0
        else
            selected_irq = 3'd0;
    end

    // Precompute vector offset for vectored mode
    wire [31:0] vector_offset = {29'b0, selected_irq} << 3;
    wire [31:0] vectored_isr_addr = VECTOR_BASE + vector_offset;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_status <= 8'h00;
            irq_active <= 1'b0;
            isr_addr <= 32'h0000_0000;
        end else if (irq_ack) begin
            irq_active <= 1'b0;
        end else if (has_pending_irq && !irq_active) begin
            irq_status <= irq_status | pending_irqs;
            irq_active <= 1'b1;
            isr_addr <= mode_sel ? vectored_isr_addr : DIRECT_BASE;
        end
    end
endmodule