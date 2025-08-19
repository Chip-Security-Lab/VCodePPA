module MemMappedIVMU (
    input wire clk, rst_n,
    input wire [7:0] addr,
    input wire [31:0] wdata,
    input wire wr_en, rd_en,
    input wire [15:0] irq_sources,
    output reg [31:0] rdata,
    output reg [31:0] irq_vector,
    output reg irq_valid
);
    reg [31:0] regs [0:17]; // 0-15: Vector table, 16: Mask, 17: Status
    wire [15:0] masked_irq;
    integer i;
    
    assign masked_irq = irq_sources & ~regs[16][15:0];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 18; i = i + 1) regs[i] <= 0;
            irq_valid <= 0; rdata <= 0;
        end else begin
            if (wr_en) regs[addr[4:0]] <= wdata;
            if (rd_en) rdata <= regs[addr[4:0]];
            
            irq_valid <= |masked_irq;
            irq_vector <= 0;
            for (i = 15; i >= 0; i = i - 1)
                if (masked_irq[i]) irq_vector <= regs[i];
            
            regs[17] <= {16'h0, masked_irq};
        end
    end
endmodule