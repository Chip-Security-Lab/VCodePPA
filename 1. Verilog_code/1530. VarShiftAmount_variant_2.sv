//SystemVerilog
//IEEE 1364-2005
module VarShiftAmount #(
    parameter MAX_SHIFT = 4,
    parameter WIDTH = 8
) (
    input wire clk,
    input wire [MAX_SHIFT-1:0] shift_num,
    input wire dir,  // 0-left 1-right
    input wire [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

    // 直接将组合逻辑放在输入端，不经过寄存器
    wire [WIDTH-1:0] shifted_left = din << shift_num;
    wire [WIDTH-1:0] shifted_right = din >> shift_num;
    wire [WIDTH-1:0] shifted_result = dir ? shifted_right : shifted_left;
    
    // 第一级寄存器：将组合逻辑结果直接寄存
    reg [WIDTH-1:0] shift_result_reg;
    
    always @(posedge clk) begin
        shift_result_reg <= shifted_result;
    end
    
    // 最终输出级
    always @(posedge clk) begin
        dout <= shift_result_reg;
    end

endmodule