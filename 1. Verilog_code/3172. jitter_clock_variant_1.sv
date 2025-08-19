//SystemVerilog
module jitter_clock(
    input clk_in,
    input rst,
    input [2:0] jitter_amount,
    input jitter_en,
    output reg clk_out
);
    reg [4:0] counter;
    reg [2:0] jitter;
    wire [2:0] jitter_pattern;
    
    // 提取公共子表达式，减少重复计算
    assign jitter_pattern = {^counter, counter[1:0]};
    
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter <= 5'd0;
            clk_out <= 1'b0;
            jitter <= 3'd0;
        end else begin
            // 计算新的抖动值 - 仅在jitter_en时应用
            jitter <= jitter_en ? (jitter_pattern & jitter_amount) : 3'd0;
            
            // 简化条件判断逻辑，避免重复计算
            if (counter >= (5'd16 - (jitter_en ? (jitter_pattern & jitter_amount) : 3'd0))) begin
                counter <= 5'd0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 5'd1;
            end
        end
    end
endmodule