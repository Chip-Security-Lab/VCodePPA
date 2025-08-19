//SystemVerilog
module enabled_comp_with_valid #(parameter WIDTH = 4)(
    input clock, reset, enable,
    input [WIDTH-1:0] in_values [0:WIDTH-1],
    output reg [$clog2(WIDTH)-1:0] highest_idx,
    output reg valid_result
);
    integer j;
    reg [$clog2(WIDTH)-1:0] highest_idx_comb;
    reg [WIDTH-1:0] max_value_comb;
    reg enable_reg;
    
    // 组合逻辑计算最大值和索引
    always @(*) begin
        max_value_comb = in_values[0];
        highest_idx_comb = 0;
        
        for (j = 1; j < WIDTH; j = j + 1) begin
            if (in_values[j] > max_value_comb) begin
                max_value_comb = in_values[j];
                highest_idx_comb = j[$clog2(WIDTH)-1:0];
            end
        end
    end
    
    // 输出寄存器在组合逻辑之后
    always @(posedge clock) begin
        if (reset) begin
            highest_idx <= 0;
            valid_result <= 0;
            enable_reg <= 0;
        end else begin
            enable_reg <= enable;
            
            if (enable) begin
                highest_idx <= highest_idx_comb;
                valid_result <= 1;
            end else begin
                valid_result <= 0;
            end
        end
    end
endmodule