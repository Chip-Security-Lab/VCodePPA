//SystemVerilog
module shift_bidir_sync #(parameter WIDTH=16) (
    input clk, rst,
    input dir,  // 0:left, 1:right
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

localparam SUB_WIDTH = 8;

wire [SUB_WIDTH-1:0] one_complement;
wire [SUB_WIDTH-1:0] right_shifted;
wire [SUB_WIDTH-1:0] left_shifted;

// 补码加法实现右移操作的减法运算单元（8位）
assign one_complement = ~din[SUB_WIDTH-1:0] + 8'b1;
assign right_shifted = (din[SUB_WIDTH-1:0] + one_complement) >> 1;
assign left_shifted  = din[SUB_WIDTH-1:0] << 1;

reg [WIDTH-1:0] result;

always @(posedge clk or posedge rst) begin
    if (rst)
        result <= {WIDTH{1'b0}};
    else begin
        if (dir)
            result[SUB_WIDTH-1:0] <= right_shifted;
        else
            result[SUB_WIDTH-1:0] <= left_shifted;
        result[WIDTH-1:SUB_WIDTH] <= { (WIDTH-SUB_WIDTH){1'b0} };
    end
end

always @(posedge clk or posedge rst) begin
    if (rst)
        dout <= {WIDTH{1'b0}};
    else
        dout <= result;
end

endmodule