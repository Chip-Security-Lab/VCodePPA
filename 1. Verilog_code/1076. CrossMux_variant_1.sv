//SystemVerilog
module CrossMux #(parameter DW=8) (
    input clk,
    input [3:0][DW-1:0] in,
    input [1:0] x_sel, y_sel,
    output reg [DW+1:0] out
);

reg [DW-1:0] in_x_sel_q;
reg [1:0] y_sel_q;
reg parity_q;

// Forward retiming: move registers after the combinational logic
wire [DW-1:0] in_x_sel_w;
wire [1:0] y_sel_w;
wire parity_w;

assign in_x_sel_w = in[x_sel];
assign parity_w = ^in[x_sel];
assign y_sel_w = y_sel;

always @(posedge clk) begin
    in_x_sel_q <= in_x_sel_w;
    parity_q   <= parity_w;
    y_sel_q    <= y_sel_w;
end

always @(posedge clk) begin
    out <= {parity_q, in_x_sel_q, y_sel_q};
end

endmodule