//SystemVerilog
// 顶层模块
module token_ring_arbiter #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] req_i,
    output wire [WIDTH-1:0] grant_o
);
    // 内部连线
    reg [WIDTH-1:0] token;
    wire token_update;
    wire [WIDTH-1:0] next_token;
    reg [WIDTH-1:0] grant_reg;

    // 当没有请求匹配当前令牌位置时，需要更新令牌
    assign token_update = !(|(token & req_i));
    
    // 令牌循环移位逻辑 - 使用条件反相减法器算法实现循环
    wire [WIDTH-1:0] token_minus_one;
    wire [WIDTH-1:0] one = 1;
    wire borrow;
    
    // 条件反相减法器实现 (token + 1 = token - (-1))
    // 使用反相减法: A - B = A + ~B + 1
    assign {borrow, token_minus_one} = {1'b0, token} + {1'b0, ~one} + 1'b1;
    
    // 带有循环处理的下一个令牌值
    assign next_token = token_update ? 
                        (token == {1'b1, {(WIDTH-1){1'b0}}}) ? 1 : token_minus_one : 
                        token;

    // 令牌寄存器逻辑
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            token <= 1; // 初始化令牌为最低位
        end else begin
            token <= next_token;
        end
    end

    // 授权生成逻辑
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            grant_reg <= 0;
        end else begin
            grant_reg <= token & req_i;
        end
    end
    
    assign grant_o = grant_reg;

endmodule