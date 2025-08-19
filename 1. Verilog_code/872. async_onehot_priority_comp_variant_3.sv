//SystemVerilog
module async_onehot_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] priority_onehot,
    output valid
);
    // 使用查找表辅助算法实现优先级编码
    reg [WIDTH-1:0] lut_output;
    wire [2:0] addr_index;
    wire [2:0] subtractor_input_a;
    wire [2:0] subtractor_input_b;
    wire [2:0] subtraction_result;
    reg [2:0] lut_subtraction[0:7][0:7]; // 查找表用于3位减法
    
    // 初始化减法查找表
    integer i, j;
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                lut_subtraction[i][j] = i > j ? i - j : 0;
            end
        end
    end
    
    // 查找输入向量中的最高位1对应的索引
    assign addr_index = data_in[7] ? 3'd7 :
                        data_in[6] ? 3'd6 :
                        data_in[5] ? 3'd5 :
                        data_in[4] ? 3'd4 :
                        data_in[3] ? 3'd3 :
                        data_in[2] ? 3'd2 :
                        data_in[1] ? 3'd1 :
                        data_in[0] ? 3'd0 : 3'd0;
    
    // 基于减法运算的查找表实现
    assign subtractor_input_a = addr_index;
    assign subtractor_input_b = data_in[0] ? 3'd1 : 3'd0;
    assign subtraction_result = lut_subtraction[subtractor_input_a][subtractor_input_b];
    
    // 基于查找表的one-hot转换
    always @(*) begin
        lut_output = 8'b0;
        case(subtraction_result)
            3'd7: lut_output = 8'b10000000;
            3'd6: lut_output = 8'b01000000;
            3'd5: lut_output = 8'b00100000;
            3'd4: lut_output = 8'b00010000;
            3'd3: lut_output = 8'b00001000;
            3'd2: lut_output = 8'b00000100;
            3'd1: lut_output = 8'b00000010;
            3'd0: lut_output = 8'b00000001;
            default: lut_output = 8'b00000000;
        endcase
    end
    
    // 仅当有效输入存在时才输出one-hot值
    assign priority_onehot = lut_output & {8{|data_in}};
    assign valid = |data_in;
endmodule