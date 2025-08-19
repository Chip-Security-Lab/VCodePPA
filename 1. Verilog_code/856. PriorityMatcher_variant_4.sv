//SystemVerilog
module PriorityMatcher #(parameter WIDTH=8, DEPTH=4) (
    input [WIDTH-1:0] data,
    input [DEPTH*WIDTH-1:0] patterns,
    output reg [$clog2(DEPTH)-1:0] match_index,
    output reg valid
);
    // 使用wire数组来存储比较结果，便于综合优化
    wire [DEPTH-1:0] match_vector;
    
    // 并行计算所有比较结果
    genvar g;
    generate
        for (g = 0; g < DEPTH; g = g + 1) begin : match_gen
            assign match_vector[g] = (data == patterns[g*WIDTH +: WIDTH]);
        end
    endgenerate
    
    // 优先级编码器实现
    always @* begin
        valid = |match_vector; // 使用或归约判断是否有匹配
        match_index = 0;
        
        // 使用casez进行优先级编码，比if-else链更高效
        casez (match_vector)
            // 从低位到高位检查，保持优先级
            {DEPTH{1'b0}}: begin
                valid = 1'b0;
            end
            default: begin
                // 优先编码逻辑
                integer i;
                for (i = DEPTH-1; i >= 0; i = i - 1) begin
                    if (match_vector[i]) begin
                        match_index = i[$clog2(DEPTH)-1:0];
                    end
                end
            end
        endcase
    end
endmodule