//SystemVerilog
module shift_var_step #(parameter WIDTH=8) (
    input clk,
    input rst,
    input [$clog2(WIDTH)-1:0] step,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

wire [WIDTH-1:0] two_complement_step;
wire [WIDTH-1:0] temp_add_operand;
wire [WIDTH-1:0] shift_result;

// 组合逻辑部分前移，将寄存器移到组合逻辑之后
assign two_complement_step = ~{ {(WIDTH-($clog2(WIDTH))){1'b0}}, step } + 1'b1;
assign temp_add_operand = din + two_complement_step;
assign shift_result = din << step;

reg [WIDTH-1:0] shift_result_reg;

always @(posedge clk or posedge rst) begin
    if (rst)
        shift_result_reg <= {WIDTH{1'b0}};
    else
        shift_result_reg <= shift_result;
end

always @(posedge clk or posedge rst) begin
    if (rst)
        dout <= {WIDTH{1'b0}};
    else
        dout <= shift_result_reg;
end

endmodule