//SystemVerilog
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
    
    // Buffered high fanout signals
    reg [7:0] effective_irqs_reg;
    reg [DATA_WIDTH-1:0] pending_reg_val_reg;
    reg [DATA_WIDTH-1:0] wdata_val_reg;
    reg [DATA_WIDTH-1:0] propagate_reg;
    reg [DATA_WIDTH:0] borrow_reg [0:1];
    
    wire [7:0] effective_irqs = irq_in & ~regs[IRQ_MASK_REG];
    wire [DATA_WIDTH-1:0] pending_cleared;
    
    // First stage buffer registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            effective_irqs_reg <= 0;
            pending_reg_val_reg <= 0;
            wdata_val_reg <= 0;
            propagate_reg <= 0;
            borrow_reg[0] <= 0;
        end else begin
            effective_irqs_reg <= effective_irqs;
            pending_reg_val_reg <= regs[IRQ_PENDING_REG];
            wdata_val_reg <= wdata;
            propagate_reg <= ~regs[IRQ_PENDING_REG];
            borrow_reg[0] <= 0;
        end
    end
    
    // Borrow generation logic with pipelining
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin: borrow_gen
            wire borrow_temp;
            assign borrow_temp = (wdata_val_reg[i] & propagate_reg[i]) | 
                               (wdata_val_reg[i] & borrow_reg[0][i]) | 
                               (propagate_reg[i] & borrow_reg[0][i]);
            
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    borrow_reg[1][i+1] <= 0;
                else
                    borrow_reg[1][i+1] <= borrow_temp;
            end
        end
    endgenerate
    
    // Compute difference using buffered borrow
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin: diff_gen
            assign pending_cleared[i] = pending_reg_val_reg[i] ^ wdata_val_reg[i] ^ borrow_reg[1][i];
        end
    endgenerate
    
    integer j;
    initial begin
        for (j = 0; j < 2**ADDR_WIDTH; j = j + 1) begin
            regs[j] = 0;
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
            if (write_en) begin
                regs[addr] <= wdata;
                if (addr == IRQ_PENDING_REG)
                    regs[IRQ_PENDING_REG] <= pending_cleared & pending_reg_val_reg;
            end
            
            if (read_en) rdata <= regs[addr];
            
            regs[IRQ_STATUS_REG] <= irq_in;
            regs[IRQ_PENDING_REG] <= regs[IRQ_PENDING_REG] | effective_irqs_reg;
            irq_out <= |(regs[IRQ_PENDING_REG]);
        end
    end
endmodule