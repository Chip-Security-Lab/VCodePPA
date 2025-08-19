//SystemVerilog
module hybrid_reset_dist(
    input wire clk,
    input wire async_rst,
    input wire sync_rst,
    input wire [3:0] mode_select,
    output reg [3:0] reset_out
);
    // 创建组合控制信号以用于if-else结构
    reg [1:0] reset_mode;
    
    // 组合逻辑部分：使用if-else级联结构定义控制信号
    always @(*) begin
        if (async_rst) begin
            reset_mode = 2'b01; // 异步复位优先
        end else if (sync_rst) begin
            reset_mode = 2'b10; // 同步复位
        end else begin
            reset_mode = 2'b00; // 无复位
        end
    end
    
    // 时序逻辑部分：基于控制信号的if-else结构
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            // 保持异步复位的直接响应能力
            reset_out <= 4'b1111;
        end else begin
            if (reset_mode == 2'b01) begin
                reset_out <= 4'b1111;                  // 异步复位
            end else if (reset_mode == 2'b10) begin
                reset_out <= mode_select & 4'b1111;    // 同步复位
            end else if (reset_mode == 2'b00) begin
                reset_out <= 4'b0000;                  // 无复位
            end else begin
                reset_out <= 4'b1111;                  // 默认为复位状态(安全)
            end
        end
    end
endmodule