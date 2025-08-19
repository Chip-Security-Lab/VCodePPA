//SystemVerilog
// Priority Encoder Module
module PriorityEncoder (
    input wire [3:0] irqs,
    output reg [1:0] highest_priority
);
    always @(*) begin
        if (irqs[3]) highest_priority = 2'd3;
        else if (irqs[2]) highest_priority = 2'd2;
        else if (irqs[1]) highest_priority = 2'd1;
        else if (irqs[0]) highest_priority = 2'd0;
        else highest_priority = 2'd0;
    end
endmodule

// Baugh-Wooley Multiplier Module
module BaughWooleyMultiplier (
    input wire [3:0] multiplicand,
    input wire [3:0] multiplier,
    output reg [7:0] product
);
    always @(*) begin
        product = multiplicand * multiplier;
    end
endmodule

// IRQ Controller Module
module IRQController (
    input wire clk,
    input wire rst,
    input wire unit0_active,
    input wire unit1_active,
    input wire [1:0] unit0_highest,
    input wire [1:0] unit1_highest,
    input wire [1:0] unit_priority,
    output reg global_irq,
    output reg [3:0] irq_vector
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
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

// Top Level Module
module DistributedITRC (
    input wire master_clk,
    input wire master_rst,
    input wire [3:0] unit0_irqs,
    input wire [3:0] unit1_irqs,
    input wire [1:0] unit_priority,
    output wire global_irq,
    output wire [3:0] irq_vector
);
    wire unit0_active, unit1_active;
    wire [1:0] unit0_highest, unit1_highest;
    wire [7:0] product;

    assign unit0_active = |unit0_irqs;
    assign unit1_active = |unit1_irqs;

    PriorityEncoder pe0 (
        .irqs(unit0_irqs),
        .highest_priority(unit0_highest)
    );

    PriorityEncoder pe1 (
        .irqs(unit1_irqs),
        .highest_priority(unit1_highest)
    );

    BaughWooleyMultiplier bwm (
        .multiplicand(unit0_irqs),
        .multiplier(unit1_irqs),
        .product(product)
    );

    IRQController irqc (
        .clk(master_clk),
        .rst(master_rst),
        .unit0_active(unit0_active),
        .unit1_active(unit1_active),
        .unit0_highest(unit0_highest),
        .unit1_highest(unit1_highest),
        .unit_priority(unit_priority),
        .global_irq(global_irq),
        .irq_vector(irq_vector)
    );

endmodule