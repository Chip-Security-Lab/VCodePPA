module int_ctrl_edge_detect #(WIDTH=8)(
    input clk,
    input [WIDTH-1:0] async_int,
    output [WIDTH-1:0] edge_out
);
reg [WIDTH-1:0] sync_reg, prev_reg;
always @(posedge clk) begin
    prev_reg <= sync_reg;
    sync_reg <= async_int;
end
assign edge_out = sync_reg & ~prev_reg;
endmodule