//SystemVerilog
module fixed_prio_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    // 优化后的一热码优先级编码器实现
    reg [WIDTH-1:0] decoded_priority;
    
    // 简化的优先级编码 - 直接使用组合逻辑表达优先级，避免多个always块和不必要的计算
    always @(*) begin
        if (req_i[0])
            decoded_priority = 4'b0001;      // 优先级0（最高）
        else if (req_i[1])
            decoded_priority = 4'b0010;      // 优先级1
        else if (req_i[2])
            decoded_priority = 4'b0100;      // 优先级2
        else if (req_i[3])
            decoded_priority = 4'b1000;      // 优先级3（最低）
        else
            decoded_priority = {WIDTH{1'b0}}; // 无请求
    end
    
    // 时序逻辑 - 在时钟边沿更新授权输出
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
        end else begin
            grant_o <= decoded_priority;
        end
    end
endmodule