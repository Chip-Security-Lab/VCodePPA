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
    
    // Pipeline stage 1 signals
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [DATA_WIDTH-1:0] wdata_stage1;
    reg write_en_stage1, read_en_stage1;
    reg [7:0] irq_in_stage1;
    wire [7:0] effective_irqs_stage1 = irq_in_stage1 & ~regs[IRQ_MASK_REG];
    
    // Pipeline stage 2 signals
    reg [ADDR_WIDTH-1:0] addr_stage2;
    reg [DATA_WIDTH-1:0] wdata_stage2;
    reg write_en_stage2, read_en_stage2;
    reg [7:0] irq_in_stage2;
    reg [7:0] effective_irqs_stage2;
    
    // Pipeline stage 3 signals
    reg [ADDR_WIDTH-1:0] addr_stage3;
    reg [DATA_WIDTH-1:0] wdata_stage3;
    reg write_en_stage3, read_en_stage3;
    reg [7:0] irq_in_stage3;
    reg [7:0] effective_irqs_stage3;
    reg [DATA_WIDTH-1:0] regs_stage3 [0:2**ADDR_WIDTH-1];
    
    integer i;
    initial begin
        for (i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
            regs[i] = 0;
        end
    end
    
    // Stage 1: Input sampling and initial processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            wdata_stage1 <= 0;
            write_en_stage1 <= 0;
            read_en_stage1 <= 0;
            irq_in_stage1 <= 0;
        end else begin
            addr_stage1 <= addr;
            wdata_stage1 <= wdata;
            write_en_stage1 <= write_en;
            read_en_stage1 <= read_en;
            irq_in_stage1 <= irq_in;
        end
    end
    
    // Stage 2: Register access and IRQ processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= 0;
            wdata_stage2 <= 0;
            write_en_stage2 <= 0;
            read_en_stage2 <= 0;
            irq_in_stage2 <= 0;
            effective_irqs_stage2 <= 0;
        end else begin
            addr_stage2 <= addr_stage1;
            wdata_stage2 <= wdata_stage1;
            write_en_stage2 <= write_en_stage1;
            read_en_stage2 <= read_en_stage1;
            irq_in_stage2 <= irq_in_stage1;
            effective_irqs_stage2 <= effective_irqs_stage1;
        end
    end
    
    // Stage 3: Register update and output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage3 <= 0;
            wdata_stage3 <= 0;
            write_en_stage3 <= 0;
            read_en_stage3 <= 0;
            irq_in_stage3 <= 0;
            effective_irqs_stage3 <= 0;
            rdata <= 0;
            irq_out <= 0;
            for (i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
                regs[i] <= 0;
            end
        end else begin
            addr_stage3 <= addr_stage2;
            wdata_stage3 <= wdata_stage2;
            write_en_stage3 <= write_en_stage2;
            read_en_stage3 <= read_en_stage2;
            irq_in_stage3 <= irq_in_stage2;
            effective_irqs_stage3 <= effective_irqs_stage2;
            
            // Write operation
            if (write_en_stage3) begin
                regs[addr_stage3] <= wdata_stage3;
                if (addr_stage3 == IRQ_PENDING_REG)
                    regs[IRQ_PENDING_REG] <= regs[IRQ_PENDING_REG] & ~wdata_stage3;
            end
            
            // Read operation
            if (read_en_stage3) rdata <= regs[addr_stage3];
            
            // Update status register
            regs[IRQ_STATUS_REG] <= irq_in_stage3;
            
            // Update pending register
            regs[IRQ_PENDING_REG] <= regs[IRQ_PENDING_REG] | effective_irqs_stage3;
            
            // Global interrupt output
            irq_out <= |(regs[IRQ_PENDING_REG]);
        end
    end
endmodule