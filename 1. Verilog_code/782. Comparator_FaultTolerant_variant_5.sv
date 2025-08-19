//SystemVerilog
module Comparator_FaultTolerant #(
    parameter WIDTH = 8,
    parameter PARITY_TYPE = 0    // 0:偶校验 1:奇校验
)(
    input  [WIDTH:0]   data_a,   // [WIDTH]为校验位
    input  [WIDTH:0]   data_b,
    output reg         safe_equal
);

    // 校验位计算和比较信号
    reg parity_ok_a;
    reg parity_ok_b;
    wire [WIDTH-1:0] data_compare;
    wire data_equal;
    
    // 数据比较逻辑
    assign data_compare = data_a[WIDTH-1:0] ^ data_b[WIDTH-1:0];
    assign data_equal = ~|data_compare;
    
    // 数据A校验位验证
    always @(*) begin
        if (PARITY_TYPE == 0) begin
            parity_ok_a = (^data_a[WIDTH-1:0]) == data_a[WIDTH];
        end else begin
            parity_ok_a = (^data_a[WIDTH-1:0]) == ~data_a[WIDTH];
        end
    end
    
    // 数据B校验位验证
    always @(*) begin
        if (PARITY_TYPE == 0) begin
            parity_ok_b = (^data_b[WIDTH-1:0]) == data_b[WIDTH];
        end else begin
            parity_ok_b = (^data_b[WIDTH-1:0]) == ~data_b[WIDTH];
        end
    end
    
    // 安全相等条件判断
    always @(*) begin
        safe_equal = parity_ok_a && parity_ok_b && data_equal;
    end

endmodule