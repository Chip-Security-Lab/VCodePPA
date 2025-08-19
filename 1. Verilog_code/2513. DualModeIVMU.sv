module DualModeIVMU #(
    parameter DIRECT_BASE = 32'hB000_0000,
    parameter VECTOR_BASE = 32'hB100_0000
)(
    input clk, rst_n,
    input [7:0] interrupt,
    input mode_sel, // 0=direct, 1=vectored
    input irq_ack,
    output reg [31:0] isr_addr,
    output reg irq_active
);
    reg [7:0] irq_status;
    wire [7:0] new_irqs;
    integer i;
    
    assign new_irqs = interrupt & ~irq_status;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_status <= 8'h0;
            irq_active <= 1'b0;
            isr_addr <= 32'h0;
        end else if (irq_ack) begin
            irq_active <= 1'b0;
        end else if (|new_irqs && !irq_active) begin
            irq_status <= irq_status | new_irqs;
            irq_active <= 1'b1;
            
            if (mode_sel) begin // Vectored mode
                for (i = 7; i >= 0; i = i - 1) begin
                    if (new_irqs[i])
                        isr_addr <= VECTOR_BASE + (i << 3);
                end
            end else // Direct mode
                isr_addr <= DIRECT_BASE;
        end
    end
endmodule