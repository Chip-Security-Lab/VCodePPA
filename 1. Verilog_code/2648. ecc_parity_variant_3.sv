//SystemVerilog
module ecc_parity #(
    parameter DATA_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] data_in,
    input parity_in,
    output reg error_flag,
    output reg [DATA_WIDTH-1:0] data_corrected
);
    // 使用先行借位算法计算奇偶校验
    reg [DATA_WIDTH:0] borrow_chain;
    reg [DATA_WIDTH-1:0] calc_parity_bits;
    reg calc_parity;
    
    integer i;
    
    // 组合逻辑实现
    always @(*) begin
        // 初始借位为0
        borrow_chain[0] = 1'b0;
        
        // 生成借位链和奇偶校验位
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin
            calc_parity_bits[i] = data_in[i] ^ borrow_chain[i];
            
            // 使用if-else替代条件运算符
            if (data_in[i]) begin
                borrow_chain[i+1] = borrow_chain[i];
            end
            else begin
                borrow_chain[i+1] = 1'b1;
            end
        end
        
        // 计算最终的奇偶校验位
        calc_parity = ^calc_parity_bits;
        
        // 检测错误
        error_flag = calc_parity ^ parity_in;
        
        // 使用if-else替代条件运算符进行数据修正
        if (error_flag) begin
            data_corrected = ~data_in;
        end
        else begin
            data_corrected = data_in;
        end
    end
endmodule