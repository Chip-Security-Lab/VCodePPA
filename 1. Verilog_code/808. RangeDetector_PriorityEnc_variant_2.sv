//SystemVerilog
module RangeDetector_PriorityEnc #(
    parameter WIDTH = 8,
    parameter ZONES = 4
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] zone_limits [ZONES:0],
    output reg [$clog2(ZONES)-1:0] zone_num
);

    // 并行前缀计算比较结果
    wire [ZONES-1:0] in_range;
    wire [ZONES-1:0] prefix_greater_equal [WIDTH:0];
    wire [ZONES-1:0] prefix_less_than [WIDTH:0];
    
    // 初始化前缀网络
    genvar i, j;
    generate
        // 初始条件
        for (i = 0; i < ZONES; i = i + 1) begin : init_prefix
            assign prefix_greater_equal[0][i] = 1'b1; // 默认大于等于
            assign prefix_less_than[0][i] = 1'b1; // 默认小于
        end

        // 位级并行计算
        for (j = 0; j < WIDTH; j = j + 1) begin : bit_prefix
            for (i = 0; i < ZONES; i = i + 1) begin : zone_compare
                // 对每个比特位进行并行比较
                wire bit_ge = (data_in[j] > zone_limits[i][j]) || 
                             (data_in[j] == zone_limits[i][j] && prefix_greater_equal[j][i]);
                wire bit_lt = (data_in[j] < zone_limits[i+1][j]) || 
                             (data_in[j] == zone_limits[i+1][j] && prefix_less_than[j][i]);
                
                assign prefix_greater_equal[j+1][i] = bit_ge;
                assign prefix_less_than[j+1][i] = bit_lt;
            end
        end
        
        // 最终结果合并
        for (i = 0; i < ZONES; i = i + 1) begin : final_result
            assign in_range[i] = prefix_greater_equal[WIDTH][i] && prefix_less_than[WIDTH][i];
        end
    endgenerate
    
    // 优先编码器优化实现 - 使用并行编码方式
    reg [$clog2(ZONES)-1:0] priority_encoder [ZONES:0];
    
    always @(*) begin
        priority_encoder[0] = 0;
        for (integer k = 0; k < ZONES; k = k + 1) begin
            priority_encoder[k+1] = in_range[k] ? k : priority_encoder[k];
        end
        zone_num = priority_encoder[ZONES];
    end
    
endmodule