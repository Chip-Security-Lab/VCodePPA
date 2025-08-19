//SystemVerilog
module level_async_ismu #(parameter WIDTH = 8)(
    input [WIDTH-1:0] irq_in,
    input [WIDTH-1:0] mask,
    input clear_n,
    output [WIDTH-1:0] active_irq,
    output irq_present
);
    wire [WIDTH-1:0] masked_result;
    wire [WIDTH-1:0] borrow;
    
    // 使用先行借位减法器算法实现
    // 生成借位信号
    assign borrow[0] = mask[0];
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_borrow
            assign borrow[i] = mask[i] | (mask[i-1] & borrow[i-1]);
        end
    endgenerate
    
    // 计算减法结果
    assign masked_result = irq_in ^ mask ^ borrow;
    
    // 根据clear_n信号控制输出
    assign active_irq = clear_n ? masked_result : {WIDTH{1'b0}};
    
    // 重新实现irq_present逻辑
    wire has_irq = |irq_in;
    wire has_valid_mask = |(~mask);
    assign irq_present = has_irq & has_valid_mask & clear_n;
endmodule