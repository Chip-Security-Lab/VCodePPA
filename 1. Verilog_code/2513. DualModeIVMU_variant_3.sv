//SystemVerilog
module DualModeIVMU #(
    parameter DIRECT_BASE = 32'hB000_0000,
    parameter VECTOR_BASE = 32'hB100_0000
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  interrupt,
    input  wire        mode_sel,      // 0=direct, 1=vectored
    input  wire        irq_ack,
    output reg  [31:0] isr_addr,
    output reg         irq_active
);

    // Stage 1: Edge Detection and New IRQ Latch
    reg  [7:0] irq_status_reg;
    wire [7:0] new_irq_mask;
    reg        new_irq_valid_stage1;
    reg  [2:0] highest_irq_index_stage1;

    assign new_irq_mask = interrupt & ~irq_status_reg;

    // Find highest priority IRQ (stage 1)
    integer idx;
    always @(*) begin : find_highest_irq_stage1
        new_irq_valid_stage1 = 1'b0;
        highest_irq_index_stage1 = 3'd0;
        for (idx = 7; idx >= 0; idx = idx - 1) begin
            if (new_irq_mask[idx] && !new_irq_valid_stage1) begin
                highest_irq_index_stage1 = idx[2:0];
                new_irq_valid_stage1 = 1'b1;
            end
        end
    end

    // Stage 2: Pipeline Registering (retimed: move output registers here)
    reg [7:0] irq_status_stage2;
    reg       new_irq_valid_stage2;
    reg [2:0] highest_irq_index_stage2;
    reg       mode_sel_stage2;
    reg [31:0] isr_addr_stage2;
    reg        irq_active_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_status_stage2        <= 8'd0;
            new_irq_valid_stage2     <= 1'b0;
            highest_irq_index_stage2 <= 3'd0;
            mode_sel_stage2          <= 1'b0;
            isr_addr_stage2          <= 32'd0;
            irq_active_stage2        <= 1'b0;
        end else begin
            irq_status_stage2        <= irq_status_reg | new_irq_mask;
            new_irq_valid_stage2     <= new_irq_valid_stage1;
            highest_irq_index_stage2 <= highest_irq_index_stage1;
            mode_sel_stage2          <= mode_sel;
            // Moved output register logic from stage3 to here
            if (irq_ack) begin
                irq_active_stage2 <= 1'b0;
            end else if (new_irq_valid_stage1 && !irq_active_stage2) begin
                irq_active_stage2 <= 1'b1;
                if (mode_sel) begin
                    isr_addr_stage2 <= VECTOR_BASE + (highest_irq_index_stage1 << 3);
                end else begin
                    isr_addr_stage2 <= DIRECT_BASE;
                end
            end
        end
    end

    // Output Registers (now only a short register stage)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            isr_addr        <= 32'd0;
            irq_active      <= 1'b0;
            irq_status_reg  <= 8'd0;
        end else begin
            isr_addr   <= isr_addr_stage2;
            irq_active <= irq_active_stage2;
            // Update irq_status only when a new irq is accepted and not already active
            if (new_irq_valid_stage1 && !irq_active_stage2)
                irq_status_reg <= irq_status_stage2;
            else if (irq_ack)
                irq_status_reg <= irq_status_reg & ~interrupt;
        end
    end

endmodule