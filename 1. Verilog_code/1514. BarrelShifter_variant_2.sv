//SystemVerilog
// IEEE 1364-2005 Verilog standard
module BarrelShifter #(parameter SIZE=16, SHIFT_WIDTH=4) (
    input [SIZE-1:0] din,
    input [SHIFT_WIDTH-1:0] shift,
    input en, left,
    output reg [SIZE-1:0] dout
);

    // 使用单独的线网来保存中间结果，优化逻辑路径
    reg [SIZE-1:0] shift_left, shift_right;
    
    // 通过分离左移和右移操作，使逻辑路径并行化
    always @* begin
        shift_left = din << shift;
        shift_right = din >> shift;
    end
    
    // 最终输出逻辑
    always @* begin
        if (!en)
            dout = {SIZE{1'b0}};
        else
            dout = left ? shift_left : shift_right;
    end

endmodule