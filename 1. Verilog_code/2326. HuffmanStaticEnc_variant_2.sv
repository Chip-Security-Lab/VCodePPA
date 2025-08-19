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
    // 查找表定义
    reg [CODE_W-1:0] lut [0:(1<<SYM_W)-1];
    
    // 流水线寄存器
    reg [SYM_W-1:0] symbol_stage1;
    reg [CODE_W-1:0] code_stage1;
    reg valid_stage1;
    
    // 使用条件求和减法算法的信号
    reg [SYM_W-1:0] symbol_adjusted;
    wire [SYM_W-1:0] offset;
    wire [SYM_W-1:0] borrow_out;
    
    // 初始化查找表
    initial begin
        $readmemb("huffman_table.mem", lut);
    end
    
    // 固定偏移值（可根据需要调整）
    assign offset = 4'h8;
    
    // 实现条件求和减法算法 - 计算 symbol_adjusted = symbol - offset
    ConditionalSumSubtractor #(
        .WIDTH(SYM_W)
    ) subtractor (
        .a(symbol),
        .b(offset),
        .diff(symbol_adjusted),
        .borrow_out(borrow_out)
    );
    
    // 第一级流水线：取符号并查找编码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            symbol_stage1 <= {SYM_W{1'b0}};
            code_stage1 <= {CODE_W{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (en) begin
            // 如果borrow_out为1，表示结果为负，保持原symbol
            // 否则使用调整后的symbol_adjusted
            symbol_stage1 <= (|borrow_out) ? symbol : symbol_adjusted;
            code_stage1 <= lut[(|borrow_out) ? symbol : symbol_adjusted];
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线：输出编码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code <= {CODE_W{1'b0}};
            valid_out <= 1'b0;
        end else if (en) begin
            code <= code_stage1;
            valid_out <= valid_stage1;
        end
    end
    
endmodule

// 条件求和减法器模块
module ConditionalSumSubtractor #(
    parameter WIDTH = 8
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] diff,
    output wire [WIDTH-1:0] borrow_out
);
    wire [WIDTH-1:0] borrow;
    wire [WIDTH-1:0] partial_diff;
    
    // 第一级：计算单个位的差和借位
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: bit_sub
            if (i == 0) begin: first_bit
                assign partial_diff[i] = a[i] ^ b[i];
                assign borrow[i] = (~a[i]) & b[i];
            end else begin: other_bits
                assign partial_diff[i] = a[i] ^ b[i] ^ borrow[i-1];
                assign borrow[i] = (~a[i] & b[i]) | (~a[i] & borrow[i-1]) | (b[i] & borrow[i-1]);
            end
        end
    endgenerate
    
    // 条件求和计算最终结果
    assign diff = partial_diff;
    assign borrow_out = borrow;
    
endmodule