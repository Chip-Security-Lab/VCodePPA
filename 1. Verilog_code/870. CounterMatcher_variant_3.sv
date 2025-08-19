//SystemVerilog
module CounterMatcher #(parameter WIDTH=8) (
    input clk, rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    input valid_in,
    output valid_out,
    output reg [15:0] match_count
);
    // 第一级流水线信号
    reg [WIDTH-1:0] data_stage1, pattern_stage1;
    reg valid_stage1;
    
    // 第二级流水线信号
    reg pattern_matched_stage2;
    reg valid_stage2;
    
    // 第一级流水线 - 寄存数据和有效信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {WIDTH{1'b0}};
            pattern_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data;
            pattern_stage1 <= pattern;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线 - 执行比较并寄存结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern_matched_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            pattern_matched_stage2 <= (data_stage1 == pattern_stage1);
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线 - 更新计数器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_count <= 16'h0000;
        end else if (valid_stage2 && pattern_matched_stage2) begin
            match_count <= match_count + 16'h0001;
        end
    end
    
    // 输出有效信号
    assign valid_out = valid_stage2;
    
endmodule