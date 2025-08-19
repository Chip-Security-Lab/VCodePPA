//SystemVerilog
module shift_pattern_matcher #(parameter WIDTH = 8) (
    input clk, rst_n, data_in,
    input [WIDTH-1:0] pattern,
    output reg match_out
);
    // 流水线阶段1：数据移位寄存器
    reg [WIDTH-1:0] shift_reg_stage1;
    
    // 流水线阶段2：部分比较结果
    reg [WIDTH/2-1:0] match_upper_stage2, match_lower_stage2;
    reg [WIDTH-1:0] pattern_stage2;
    
    // 流水线阶段3：最终比较结果
    reg match_result_stage3;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 阶段1: 数据移位和捕获
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end
        else begin
            shift_reg_stage1 <= {shift_reg_stage1[WIDTH-2:0], data_in};
            valid_stage1 <= 1'b1;
        end
    end
    
    // 阶段2: 部分比较
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_upper_stage2 <= {(WIDTH/2){1'b0}};
            match_lower_stage2 <= {(WIDTH/2){1'b0}};
            pattern_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else begin
            pattern_stage2 <= pattern;
            // 分段比较，提高比较效率
            for (integer i = 0; i < WIDTH/2; i = i + 1) begin
                match_upper_stage2[i] <= (shift_reg_stage1[i+(WIDTH/2)] == pattern[i+(WIDTH/2)]);
                match_lower_stage2[i] <= (shift_reg_stage1[i] == pattern[i]);
            end
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 阶段3: 最终比较结果聚合
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_result_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end
        else begin
            // 检查所有位是否匹配
            match_result_stage3 <= &{match_upper_stage2, match_lower_stage2};
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            match_out <= 1'b0;
        else if (valid_stage3)
            match_out <= match_result_stage3;
    end
endmodule