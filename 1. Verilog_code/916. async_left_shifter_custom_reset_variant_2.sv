//SystemVerilog
module async_left_shifter_custom_reset #(
    parameter WIDTH = 8,
    parameter RESET_VAL = 8'hA5  // Custom reset pattern
)(
    input                  rstn,
    input      [WIDTH-1:0] din,
    input      [$clog2(WIDTH)-1:0] shift,
    output     [WIDTH-1:0] dout
);
    // 桶形移位器实现
    wire [WIDTH-1:0] shift_stage [0:$clog2(WIDTH)];
    
    // 初始输入赋值给第一级
    assign shift_stage[0] = din;
    
    // 生成多级移位网络
    genvar i;
    generate
        for (i = 0; i < $clog2(WIDTH); i = i + 1) begin: barrel_shift
            assign shift_stage[i+1] = shift[i] ? {shift_stage[i][WIDTH-1-(2**i):0], {(2**i){1'b0}}} : shift_stage[i];
        end
    endgenerate
    
    // 复位逻辑
    assign dout = !rstn ? RESET_VAL : shift_stage[$clog2(WIDTH)];
endmodule