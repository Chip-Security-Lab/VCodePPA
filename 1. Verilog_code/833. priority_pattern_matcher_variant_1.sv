//SystemVerilog
module priority_pattern_matcher #(parameter WIDTH = 8, PATTERNS = 4) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] patterns [PATTERNS-1:0],
    output reg [($clog2(PATTERNS))-1:0] match_idx,
    output reg match_found
);
    
    reg [PATTERNS-1:0] match_vector;
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_idx <= 0;
            match_found <= 1'b0;
        end else begin
            // 预计算所有匹配结果，减少关键路径延迟
            for (i = 0; i < PATTERNS; i = i + 1) begin
                match_vector[i] = (data_in == patterns[i]);
            end
            
            // 扁平化的优先级逻辑
            match_found <= |match_vector;
            
            if (match_vector[PATTERNS-1]) begin
                match_idx <= PATTERNS-1;
            end else if (match_vector[PATTERNS-2] && PATTERNS > 1) begin
                match_idx <= PATTERNS-2;
            end else if (match_vector[PATTERNS-3] && PATTERNS > 2) begin
                match_idx <= PATTERNS-3;
            end else if (match_vector[PATTERNS-4] && PATTERNS > 3) begin
                match_idx <= PATTERNS-4;
            end else begin
                match_idx <= 0;
            end
        end
    end
endmodule