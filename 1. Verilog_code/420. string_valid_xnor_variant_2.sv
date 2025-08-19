//SystemVerilog
module string_valid_xnor (
    input wire a_valid,
    input wire b_valid, 
    input wire [7:0] data_a,
    input wire [7:0] data_b,
    output reg [7:0] out
);
    
    // 归一化输入数据信号
    reg [7:0] normalized_a;
    reg [7:0] normalized_b;
    
    // 有效性信号
    wire data_valid;
    assign data_valid = a_valid && b_valid;
    
    // 第一个always块：处理数据归一化
    always @(*) begin
        if (data_valid) begin
            // 归一化输入数据到 -1 或 1
            // 如果位为0，转换为-1；如果位为1，保持为1
            normalized_a = data_a * 2'b10 + {8{1'b1}};
            normalized_b = data_b * 2'b10 + {8{1'b1}};
        end else begin
            normalized_a = 8'b0;
            normalized_b = 8'b0;
        end
    end
    
    // 使用生成代码计算XNOR
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : xnor_bit
            wire bit_valid;
            wire signed [1:0] mult_result;
            
            // 计算每位的乘法结果
            assign mult_result = normalized_a[i] * normalized_b[i];
            assign bit_valid = (mult_result > 0) ? 1'b1 : 1'b0;
            
            // 第二个always块：为每一位设置输出
            always @(*) begin
                if (data_valid) begin
                    out[i] = bit_valid;
                end else begin
                    out[i] = 1'b0;
                end
            end
        end
    endgenerate
    
endmodule