//SystemVerilog
module int_ctrl_edge_detect #(
    parameter WIDTH = 8
)(
    input clk,
    input [WIDTH-1:0] async_int,
    output reg [WIDTH-1:0] edge_out
);
    reg [WIDTH-1:0] async_int_reg;
    reg [WIDTH-1:0] sync_reg;
    
    always @(posedge clk) begin
        async_int_reg <= async_int;
        sync_reg <= async_int_reg;
        edge_out <= sync_reg & ~async_int_reg;
    end
endmodule