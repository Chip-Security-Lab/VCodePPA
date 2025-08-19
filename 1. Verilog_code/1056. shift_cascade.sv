module shift_cascade #(parameter WIDTH=8, DEPTH=4) (
    input clk, en,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
// 使用单独的寄存器替代数组
reg [WIDTH-1:0] shift_reg0;
reg [WIDTH-1:0] shift_reg1;
reg [WIDTH-1:0] shift_reg2;
reg [WIDTH-1:0] shift_reg3;
// 支持最多4级级联，需要时可扩展

always @(posedge clk) begin
    if (en) begin
        shift_reg0 <= data_in;
        if (DEPTH > 1) shift_reg1 <= shift_reg0;
        if (DEPTH > 2) shift_reg2 <= shift_reg1;
        if (DEPTH > 3) shift_reg3 <= shift_reg2;
    end
end

// 根据DEPTH参数选择输出
assign data_out = (DEPTH == 1) ? shift_reg0 :
                 (DEPTH == 2) ? shift_reg1 :
                 (DEPTH == 3) ? shift_reg2 : shift_reg3;
endmodule