//SystemVerilog
module HuffmanStaticEnc #(
    parameter SYM_W = 4,
    parameter CODE_W = 8
)(
    input wire clk,
    input wire rst_n,  // 添加复位信号
    input wire valid_in,  // 输入有效信号
    input wire [SYM_W-1:0] symbol,
    output reg valid_out,  // 输出有效信号
    output reg [CODE_W-1:0] code,
    output wire ready_in  // 输入就绪信号
);
    // 定义霍夫曼查找表
    reg [CODE_W-1:0] lut [0:(1<<SYM_W)-1];
    
    // 流水线寄存器和控制信号
    reg valid_stage1;
    reg [SYM_W-1:0] symbol_stage1;
    reg [CODE_W-1:0] code_stage1;
    
    // 条件求和减法器相关信号
    reg [7:0] minuend, subtrahend;
    reg [7:0] inverted_subtrahend;
    reg [7:0] sum;
    reg [8:0] adder_result; // 增加一位用于进位
    reg carry;
    
    // 始终准备接收新数据
    assign ready_in = 1'b1;
    
    // 初始化查找表
    initial begin
        $readmemb("huffman_table.mem", lut);
    end
    
    // 流水线第一级：查表和条件求和减法计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            symbol_stage1 <= {SYM_W{1'b0}};
            code_stage1 <= {CODE_W{1'b0}};
        end else begin
            valid_stage1 <= valid_in;
            symbol_stage1 <= symbol;
            
            // 条件求和减法器实现
            if (valid_in) begin
                minuend = lut[symbol];
                subtrahend = symbol;
                
                // 对减数取反
                inverted_subtrahend = ~subtrahend;
                
                // 加1并相加 (等效于减法)
                adder_result = minuend + inverted_subtrahend + 8'b00000001;
                carry = adder_result[8];
                sum = adder_result[7:0];
                
                // 条件选择结果
                if (minuend >= subtrahend) begin
                    code_stage1 <= sum;
                end else begin
                    // 如果被减数小于减数，则直接使用查表结果
                    code_stage1 <= lut[symbol];
                end
            end else begin
                code_stage1 <= {CODE_W{1'b0}};
            end
        end
    end
    
    // 流水线第二级：输出结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            code <= {CODE_W{1'b0}};
        end else begin
            valid_out <= valid_stage1;
            code <= code_stage1;
        end
    end
endmodule