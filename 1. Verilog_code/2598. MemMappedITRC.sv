module MemMappedITRC #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input wire clk, rst_n,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] wdata,
    input wire write_en, read_en,
    output reg [DATA_WIDTH-1:0] rdata,
    input wire [7:0] irq_in,
    output reg irq_out
);
    // Register map
    reg [DATA_WIDTH-1:0] regs [0:2**ADDR_WIDTH-1];
    localparam IRQ_MASK_REG = 0;
    localparam IRQ_STATUS_REG = 1;
    localparam IRQ_PENDING_REG = 2;
    
    wire [7:0] effective_irqs = irq_in & ~regs[IRQ_MASK_REG];
    
    integer i;
    initial begin
        for (i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
            regs[i] = 0;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata <= 0;
            irq_out <= 0;
            regs[IRQ_MASK_REG] <= 0;
            regs[IRQ_STATUS_REG] <= 0;
            regs[IRQ_PENDING_REG] <= 0;
        end else begin
            // Write operation
            if (write_en) begin
                regs[addr] <= wdata;
                if (addr == IRQ_PENDING_REG)
                    regs[IRQ_PENDING_REG] <= regs[IRQ_PENDING_REG] & ~wdata; // Clear acknowledged
            end
            
            // Read operation
            if (read_en) rdata <= regs[addr];
            
            // Update status register with current IRQ state
            regs[IRQ_STATUS_REG] <= irq_in;
            
            // Update pending with new IRQs
            regs[IRQ_PENDING_REG] <= regs[IRQ_PENDING_REG] | effective_irqs;
            
            // Global interrupt output
            irq_out <= |(regs[IRQ_PENDING_REG]);
        end
    end
endmodule