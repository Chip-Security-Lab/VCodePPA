//SystemVerilog
module DistributedITRC (
    input wire master_clk, master_rst,
    input wire [3:0] unit0_irqs,
    input wire [3:0] unit1_irqs,
    input wire [1:0] unit_priority,
    output reg global_irq,
    output reg [3:0] irq_vector
);

    // Internal signals
    wire unit0_active, unit1_active;
    reg [1:0] unit0_highest, unit1_highest;
    reg [1:0] unit0_highest_buf, unit1_highest_buf;
    reg [3:0] next_irq_vector;
    reg [3:0] next_irq_vector_buf;
    reg next_global_irq;
    reg d0, d0_buf;
    reg [3:0] irq_vector_pre;
    reg global_irq_pre;
    
    // Active status detection
    assign unit0_active = |unit0_irqs;
    assign unit1_active = |unit1_irqs;
    
    // Unit0 priority encoder
    always @(*) begin
        casex(unit0_irqs)
            4'b1xxx: d0 = 2'd3;
            4'b01xx: d0 = 2'd2;
            4'b001x: d0 = 2'd1;
            4'b0001: d0 = 2'd0;
            default: d0 = 2'd0;
        endcase
    end
    
    // Unit1 priority encoder
    always @(*) begin
        casex(unit1_irqs)
            4'b1xxx: unit1_highest = 2'd3;
            4'b01xx: unit1_highest = 2'd2;
            4'b001x: unit1_highest = 2'd1;
            4'b0001: unit1_highest = 2'd0;
            default: unit1_highest = 2'd0;
        endcase
    end
    
    // Buffer registers for high fanout signals
    always @(posedge master_clk or posedge master_rst) begin
        if (master_rst) begin
            d0_buf <= 2'd0;
            unit0_highest_buf <= 2'd0;
            unit1_highest_buf <= 2'd0;
            next_irq_vector_buf <= 4'd0;
            irq_vector_pre <= 4'd0;
            global_irq_pre <= 1'b0;
        end else begin
            d0_buf <= d0;
            unit0_highest_buf <= unit0_highest;
            unit1_highest_buf <= unit1_highest;
            next_irq_vector_buf <= next_irq_vector;
            irq_vector_pre <= next_irq_vector_buf;
            global_irq_pre <= next_global_irq;
        end
    end
    
    // IRQ vector selection logic
    always @(*) begin
        if (unit_priority[0] && unit0_active)
            next_irq_vector = {2'b00, unit0_highest_buf};
        else if (unit_priority[1] && unit1_active)
            next_irq_vector = {2'b10, unit1_highest_buf};
        else if (unit0_active)
            next_irq_vector = {2'b00, unit0_highest_buf};
        else if (unit1_active)
            next_irq_vector = {2'b10, unit1_highest_buf};
        else
            next_irq_vector = 4'd0;
    end
    
    // Global IRQ generation
    always @(*) begin
        next_global_irq = unit0_active || unit1_active;
    end
    
    // Sequential logic for output registers
    always @(posedge master_clk or posedge master_rst) begin
        if (master_rst) begin
            global_irq <= 1'b0;
            irq_vector <= 4'd0;
        end else begin
            global_irq <= global_irq_pre;
            irq_vector <= irq_vector_pre;
        end
    end

endmodule