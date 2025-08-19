module DistributedITRC (
    input wire master_clk, master_rst,
    input wire [3:0] unit0_irqs,
    input wire [3:0] unit1_irqs,
    input wire [1:0] unit_priority, // Which unit has higher priority
    output reg global_irq,
    output reg [3:0] irq_vector
);
    wire unit0_active, unit1_active;
    reg [1:0] unit0_highest, unit1_highest;
    
    assign unit0_active = |unit0_irqs;
    assign unit1_active = |unit1_irqs;
    
    // Priority encoder for unit0
    always @(*) begin
        if (unit0_irqs[3]) unit0_highest = 2'd3;
        else if (unit0_irqs[2]) unit0_highest = 2'd2;
        else if (unit0_irqs[1]) unit0_highest = 2'd1;
        else if (unit0_irqs[0]) unit0_highest = 2'd0;
        else unit0_highest = 2'd0;
    end
    
    // Priority encoder for unit1
    always @(*) begin
        if (unit1_irqs[3]) unit1_highest = 2'd3;
        else if (unit1_irqs[2]) unit1_highest = 2'd2;
        else if (unit1_irqs[1]) unit1_highest = 2'd1;
        else if (unit1_irqs[0]) unit1_highest = 2'd0;
        else unit1_highest = 2'd0;
    end
    
    always @(posedge master_clk or posedge master_rst) begin
        if (master_rst) begin
            global_irq <= 0;
            irq_vector <= 0;
        end else begin
            global_irq <= unit0_active || unit1_active;
            
            if (unit_priority[0] && unit0_active)
                irq_vector <= {2'b00, unit0_highest};
            else if (unit_priority[1] && unit1_active)
                irq_vector <= {2'b10, unit1_highest};
            else if (unit0_active)
                irq_vector <= {2'b00, unit0_highest};
            else if (unit1_active)
                irq_vector <= {2'b10, unit1_highest};
            else
                irq_vector <= 0;
        end
    end
endmodule