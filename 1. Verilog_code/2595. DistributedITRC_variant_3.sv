//SystemVerilog
module DistributedITRC (
    input wire master_clk, master_rst,
    input wire [3:0] unit0_irqs,
    input wire [3:0] unit1_irqs,
    input wire [1:0] unit_priority,
    output reg global_irq,
    output reg [3:0] irq_vector
);

    // Stage 1: Priority Encoding
    reg [1:0] unit0_highest_stage1, unit1_highest_stage1;
    reg unit0_active_stage1, unit1_active_stage1;
    reg [3:0] unit0_irqs_stage1, unit1_irqs_stage1;
    reg [1:0] unit_priority_stage1;

    // Stage 2: Priority Resolution
    reg [3:0] next_irq_vector_stage2;
    reg next_global_irq_stage2;
    reg [1:0] unit0_highest_stage2, unit1_highest_stage2;
    reg unit0_active_stage2, unit1_active_stage2;
    reg [1:0] unit_priority_stage2;

    // Stage 1: Priority Encoders
    always @(*) begin
        if (unit0_irqs_stage1[3]) unit0_highest_stage1 = 2'd3;
        else if (unit0_irqs_stage1[2]) unit0_highest_stage1 = 2'd2;
        else if (unit0_irqs_stage1[1]) unit0_highest_stage1 = 2'd1;
        else if (unit0_irqs_stage1[0]) unit0_highest_stage1 = 2'd0;
        else unit0_highest_stage1 = 2'd0;

        if (unit1_irqs_stage1[3]) unit1_highest_stage1 = 2'd3;
        else if (unit1_irqs_stage1[2]) unit1_highest_stage1 = 2'd2;
        else if (unit1_irqs_stage1[1]) unit1_highest_stage1 = 2'd1;
        else if (unit1_irqs_stage1[0]) unit1_highest_stage1 = 2'd0;
        else unit1_highest_stage1 = 2'd0;

        unit0_active_stage1 = |unit0_irqs_stage1;
        unit1_active_stage1 = |unit1_irqs_stage1;
    end

    // Stage 2: Priority Resolution
    always @(*) begin
        next_global_irq_stage2 = unit0_active_stage2 || unit1_active_stage2;
        
        if (unit_priority_stage2[0] && unit0_active_stage2)
            next_irq_vector_stage2 = {2'b00, unit0_highest_stage2};
        else if (unit_priority_stage2[1] && unit1_active_stage2)
            next_irq_vector_stage2 = {2'b10, unit1_highest_stage2};
        else if (unit0_active_stage2)
            next_irq_vector_stage2 = {2'b00, unit0_highest_stage2};
        else if (unit1_active_stage2)
            next_irq_vector_stage2 = {2'b10, unit1_highest_stage2};
        else
            next_irq_vector_stage2 = 0;
    end

    // Pipeline Registers
    always @(posedge master_clk or posedge master_rst) begin
        if (master_rst) begin
            // Stage 1 Registers
            unit0_irqs_stage1 <= 0;
            unit1_irqs_stage1 <= 0;
            unit_priority_stage1 <= 0;
            
            // Stage 2 Registers
            unit0_highest_stage2 <= 0;
            unit1_highest_stage2 <= 0;
            unit0_active_stage2 <= 0;
            unit1_active_stage2 <= 0;
            unit_priority_stage2 <= 0;
            
            // Output Registers
            global_irq <= 0;
            irq_vector <= 0;
        end else begin
            // Stage 1 Registers
            unit0_irqs_stage1 <= unit0_irqs;
            unit1_irqs_stage1 <= unit1_irqs;
            unit_priority_stage1 <= unit_priority;
            
            // Stage 2 Registers
            unit0_highest_stage2 <= unit0_highest_stage1;
            unit1_highest_stage2 <= unit1_highest_stage1;
            unit0_active_stage2 <= unit0_active_stage1;
            unit1_active_stage2 <= unit1_active_stage1;
            unit_priority_stage2 <= unit_priority_stage1;
            
            // Output Registers
            global_irq <= next_global_irq_stage2;
            irq_vector <= next_irq_vector_stage2;
        end
    end
endmodule