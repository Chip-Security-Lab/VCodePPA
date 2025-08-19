//SystemVerilog
module Demux_CDC #(parameter DW=8) (
    input clk_a, clk_b,
    input [DW-1:0] data_a,
    input sel_a,
    output reg [DW-1:0] data_b0,
    output reg [DW-1:0] data_b1
);
    // Pre-registered data and select signals in clock domain A
    reg sel_a_reg;
    reg [DW-1:0] data_a_reg;
    
    // Synchronization registers moved before combinational logic
    reg [DW-1:0] sync0_a, sync1_a;
    reg [DW-1:0] sync0_b, sync1_b;
    
    // Register input data and select signal in clock domain A
    always @(posedge clk_a) begin
        data_a_reg <= data_a;
        sel_a_reg <= sel_a;
    end
    
    // Move the combinational logic before the clock domain crossing
    always @(posedge clk_a) begin
        sync0_a <= sel_a_reg ? data_a_reg : {DW{1'b0}};
        sync1_a <= !sel_a_reg ? data_a_reg : {DW{1'b0}};
    end
    
    // Cross clock domains with simple registers
    always @(posedge clk_b) begin
        sync0_b <= sync0_a;
        sync1_b <= sync1_a;
    end
    
    // Final output stage
    always @(posedge clk_b) begin
        data_b0 <= sync0_b;
        data_b1 <= sync1_b;
    end
endmodule