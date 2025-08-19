module ITRC_HybridTrigger #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] level_int,
    input [WIDTH-1:0] edge_int,
    output reg [WIDTH-1:0] triggered
);
    reg [WIDTH-1:0] edge_reg;
    
    always @(posedge clk) begin
        if (!rst_n) edge_reg <= 0;
        else edge_reg <= edge_int;
    end
    
    always @* begin
        triggered = (edge_int & ~edge_reg) | (level_int & edge_int);
    end
endmodule