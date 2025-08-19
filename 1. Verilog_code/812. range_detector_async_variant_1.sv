//SystemVerilog
module range_detector_async(
    input wire clk,
    input wire rst_n,
    input wire [15:0] data_in,
    input wire [15:0] min_val, max_val,
    output reg within_range
);
    // 比较逻辑直接计算
    wire above_min_comb, below_max_comb;
    wire within_range_comb;
    
    // 计算比较结果
    assign above_min_comb = (data_in >= min_val);
    assign below_max_comb = (data_in <= max_val);
    
    // 组合结果
    assign within_range_comb = above_min_comb && below_max_comb;
    
    // 将两级流水线合并为一级，直接在组合逻辑后寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            within_range <= 1'b0;
        end else begin
            within_range <= within_range_comb;
        end
    end
endmodule