//SystemVerilog
module decoder_cascade (
    input wire clk,          // 添加时钟输入
    input wire rst_n,        // 添加复位信号
    input wire en_in,
    input wire [2:0] addr,
    output reg [7:0] decoded,
    output reg en_out
);
    // 内部信号定义 - 用于流水线
    reg en_stage1;
    reg [2:0] addr_stage1;
    reg [7:0] decoded_comb;
    
    // 流水线第一级 - 注册输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_stage1 <= 1'b0;
            addr_stage1 <= 3'b000;
        end else begin
            en_stage1 <= en_in;
            addr_stage1 <= addr;
        end
    end
    
    // 组合逻辑 - 解码部分
    always @(*) begin
        if (en_stage1) begin
            decoded_comb = (1'b1 << addr_stage1);
        end else begin
            decoded_comb = 8'h0;
        end
    end
    
    // 流水线第二级 - 注册输出信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded <= 8'h0;
            en_out <= 1'b0;
        end else begin
            decoded <= decoded_comb;
            en_out <= en_stage1;
        end
    end
    
endmodule