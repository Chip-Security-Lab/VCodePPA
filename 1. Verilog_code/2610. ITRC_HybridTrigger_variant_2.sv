//SystemVerilog
module EdgeDetector #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] edge_int,
    output reg [WIDTH-1:0] edge_reg
);
    always @(posedge clk) begin
        if (!rst_n) edge_reg <= 0;
        else edge_reg <= edge_int;
    end
endmodule

module TriggerLogic #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] edge_int,
    input [WIDTH-1:0] edge_reg,
    input [WIDTH-1:0] level_int,
    output [WIDTH-1:0] triggered
);
    wire [WIDTH-1:0] edge_diff;
    wire [WIDTH-1:0] edge_comp;
    
    // Two's complement subtraction
    assign edge_comp = ~edge_reg + 1'b1;
    assign edge_diff = edge_int + edge_comp;
    
    // Trigger logic using subtraction result
    assign triggered = (edge_diff[WIDTH-1] & edge_int) | (level_int & edge_int);
endmodule

module ITRC_HybridTrigger #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] level_int,
    input [WIDTH-1:0] edge_int,
    output [WIDTH-1:0] triggered
);
    wire [WIDTH-1:0] edge_reg;

    EdgeDetector #(
        .WIDTH(WIDTH)
    ) u_edge_detector (
        .clk(clk),
        .rst_n(rst_n),
        .edge_int(edge_int),
        .edge_reg(edge_reg)
    );

    TriggerLogic #(
        .WIDTH(WIDTH)
    ) u_trigger_logic (
        .edge_int(edge_int),
        .edge_reg(edge_reg),
        .level_int(level_int),
        .triggered(triggered)
    );
endmodule