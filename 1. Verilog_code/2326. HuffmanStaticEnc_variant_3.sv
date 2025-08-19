//SystemVerilog
module HuffmanStaticEnc #(
    parameter SYM_W = 4,
    parameter CODE_W = 8
) (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire [SYM_W-1:0] symbol,
    output reg valid_out,
    output reg [CODE_W-1:0] code,
    output wire ready
);
    // 常量定义
    localparam LUT_SIZE = (1 << SYM_W);
    
    // 优化：修改存储器声明以便综合工具选择最佳实现方式
    (* ram_style = "distributed" *) reg [CODE_W-1:0] huffman_lut [0:LUT_SIZE-1];
    
    // 流水线寄存器
    reg [SYM_W-1:0] symbol_r;
    reg valid_r;
    
    // 就绪信号，始终为高
    assign ready = 1'b1;
    
    // 初始化查找表
    initial begin
        $readmemb("huffman_table.mem", huffman_lut);
    end
    
    // 优化：合并两级流水线逻辑，减少always块数量
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            symbol_r <= {SYM_W{1'b0}};
            valid_r <= 1'b0;
            code <= {CODE_W{1'b0}};
            valid_out <= 1'b0;
        end else begin
            // 流水线第一级
            if (valid_in) begin
                symbol_r <= symbol;
                valid_r <= 1'b1;
            end else begin
                valid_r <= 1'b0;
            end
            
            // 流水线第二级
            valid_out <= valid_r;
            if (valid_r) begin
                code <= huffman_lut[symbol_r];
            end
        end
    end
    
endmodule