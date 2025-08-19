//SystemVerilog
module sr_ff_priority_reset (
    input  wire clk,   // 时钟输入
    input  wire s,     // 置位输入
    input  wire r,     // 复位输入 (优先级高)
    output reg  q      // 输出状态
);
    // 定义8位乘法器的输入和输出
    wire [7:0] multiplicand;
    wire [7:0] multiplier;
    wire [15:0] product;
    
    // 将s和r扩展为8位以用作乘法输入
    assign multiplicand = {7'b0, s};
    assign multiplier = {7'b0, ~r};  // 反转r以保持优先级逻辑
    
    // Baugh-Wooley 乘法器实现
    wire [7:0][15:0] partial_products;
    wire [15:0] sum;
    
    // 生成部分积
    genvar i, j;
    generate
        for (i = 0; i < 7; i = i + 1) begin : gen_pp_unsigned
            for (j = 0; j < 7; j = j + 1) begin : gen_pp_bits
                assign partial_products[i][j] = multiplicand[j] & multiplier[i];
            end
            // 处理有符号位
            assign partial_products[i][7] = multiplicand[7] & multiplier[i];
            // 高位填充
            assign partial_products[i][15:8] = {8{partial_products[i][7]}};
        end
    
        // 最后一行的部分积特殊处理
        for (j = 0; j < 7; j = j + 1) begin : gen_last_pp_bits
            assign partial_products[7][j] = multiplicand[j] & multiplier[7];
        end
        // 处理最后一行的有符号位
        assign partial_products[7][7] = ~(multiplicand[7] & multiplier[7]);
        // 高位填充
        assign partial_products[7][15:8] = {8{partial_products[7][7]}};
    endgenerate
    
    // 累加所有部分积
    assign sum = partial_products[0] + partial_products[1] + partial_products[2] + 
                 partial_products[3] + partial_products[4] + partial_products[5] + 
                 partial_products[6] + partial_products[7] + 16'h0080;  // 加上校正项
    
    // 最终乘积
    assign product = sum;
    
    // 组合逻辑 - 使用乘法结果确定下一状态
    reg next_state;
    
    always @(*) begin
        if (r)
            next_state = 1'b0;     // 复位条件 (优先级高)
        else if (s)
            next_state = 1'b1;     // 置位条件
        else
            next_state = q;        // 保持当前状态
            
        // 可以使用乘法结果进行辅助检查
        // 当乘法结果为非零且r不为1时，考虑置位
        if (product != 16'b0 && !r)
            next_state = 1'b1;
    end
    
    // 时序逻辑 - 更新输出状态
    always @(posedge clk) begin
        q <= next_state;           // 在时钟上升沿更新状态
    end
    
endmodule