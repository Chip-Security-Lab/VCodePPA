//SystemVerilog
module HuffmanStaticEnc #(
    parameter SYM_W = 4,
    parameter CODE_W = 8
) (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire valid_in,
    input wire [SYM_W-1:0] symbol,
    output reg [CODE_W-1:0] code,
    output reg valid_out
);
    // 霍夫曼编码查找表
    reg [CODE_W-1:0] lut [0:(1<<SYM_W)-1];
    
    // 流水线阶段1: 符号寄存器和有效信号
    reg [SYM_W-1:0] symbol_stage1;
    reg valid_stage1;
    
    // 流水线阶段2: 查表结果和有效信号
    reg [CODE_W-1:0] code_stage2;
    reg valid_stage2;
    
    // 初始化查找表
    initial begin
        $readmemb("huffman_table.mem", lut);
    end
    
    // 流水线阶段1: 注册输入符号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            symbol_stage1 <= {SYM_W{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (en) begin
            symbol_stage1 <= symbol;
            valid_stage1 <= valid_in;
        end
    end
    
    // 流水线阶段2: 查表并注册结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_stage2 <= {CODE_W{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (en) begin
            code_stage2 <= lut[symbol_stage1];
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出阶段: 传递结果到输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code <= {CODE_W{1'b0}};
            valid_out <= 1'b0;
        end else if (en) begin
            code <= code_stage2;
            valid_out <= valid_stage2;
        end
    end
    
endmodule