//SystemVerilog
module CrossMux #(parameter DW=8) (
    input clk,
    input [3:0][DW-1:0] in,
    input [1:0] x_sel, y_sel,
    output reg [DW+1:0] out
);

// 4位条件反相减法器信号
wire [3:0] minuend_4b;
wire [3:0] subtrahend_4b;
wire subtract_en;
wire [3:0] diff_4b;
wire borrow_out_4b;

assign minuend_4b     = x_sel;
assign subtrahend_4b  = y_sel;
assign subtract_en    = 1'b1;

// 条件反相减法器算法实现4位减法器
wire [3:0] subtrahend_inv_4b;
wire       carry_in_4b;
wire [3:0] sum_4b;
wire       carry_out_4b;

assign subtrahend_inv_4b = subtract_en ? ~subtrahend_4b : subtrahend_4b;
assign carry_in_4b       = subtract_en ? 1'b1 : 1'b0;
assign {carry_out_4b, sum_4b} = {1'b0, minuend_4b} + {1'b0, subtrahend_inv_4b} + carry_in_4b;
assign diff_4b = sum_4b;
assign borrow_out_4b = ~carry_out_4b;

// 前向寄存器重定时：将输入寄存器推至组合逻辑后
reg [DW-1:0] in_muxed_reg;
reg parity_reg;
reg [1:0] y_sel_reg;

always @(posedge clk) begin
    in_muxed_reg <= in[diff_4b];
    parity_reg   <= ^in[diff_4b];
    y_sel_reg    <= y_sel;
end

always @(posedge clk) begin
    out <= {parity_reg, in_muxed_reg, y_sel_reg};
end

endmodule