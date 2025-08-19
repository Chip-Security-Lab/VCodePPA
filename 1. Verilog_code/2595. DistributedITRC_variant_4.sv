//SystemVerilog
module DistributedITRC (
    input wire master_clk, master_rst,
    input wire [3:0] unit0_irqs,
    input wire [3:0] unit1_irqs,
    input wire [1:0] unit_priority,
    output reg global_irq,
    output reg [3:0] irq_vector
);

    wire unit0_active, unit1_active;
    reg [1:0] unit0_highest, unit1_highest;
    reg [3:0] next_irq_vector;
    reg next_global_irq;
    
    assign unit0_active = |unit0_irqs;
    assign unit1_active = |unit1_irqs;
    
    // Priority encoder for unit0
    always @(*) begin
        casex(unit0_irqs)
            4'b1xxx: unit0_highest = 2'd3;
            4'b01xx: unit0_highest = 2'd2;
            4'b001x: unit0_highest = 2'd1;
            4'b0001: unit0_highest = 2'd0;
            default: unit0_highest = 2'd0;
        endcase
    end
    
    // Priority encoder for unit1
    always @(*) begin
        casex(unit1_irqs)
            4'b1xxx: unit1_highest = 2'd3;
            4'b01xx: unit1_highest = 2'd2;
            4'b001x: unit1_highest = 2'd1;
            4'b0001: unit1_highest = 2'd0;
            default: unit1_highest = 2'd0;
        endcase
    end
    
    // Next state logic for irq_vector
    always @(*) begin
        if (unit_priority[0] && unit0_active)
            next_irq_vector = {2'b00, unit0_highest};
        else if (unit_priority[1] && unit1_active)
            next_irq_vector = {2'b10, unit1_highest};
        else if (unit0_active)
            next_irq_vector = {2'b00, unit0_highest};
        else if (unit1_active)
            next_irq_vector = {2'b10, unit1_highest};
        else
            next_irq_vector = 4'd0;
    end
    
    // Next state logic for global_irq
    always @(*) begin
        next_global_irq = unit0_active || unit1_active;
    end
    
    // State registers
    always @(posedge master_clk or posedge master_rst) begin
        if (master_rst) begin
            global_irq <= 0;
            irq_vector <= 0;
        end else begin
            global_irq <= next_global_irq;
            irq_vector <= next_irq_vector;
        end
    end
    
endmodule