//SystemVerilog
module CounterMatcher #(parameter WIDTH=8) (
    input clk, rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    input valid_in,           // 输入数据有效信号
    output valid_out,         // 输出数据有效信号
    output reg [15:0] match_count
);
    // Stage 1: 比较阶段
    reg [WIDTH-1:0] data_stage1, pattern_stage1;
    reg valid_stage1;
    reg match_stage1;
    
    // Stage 2: 计数阶段
    reg match_stage2;
    reg valid_stage2;
    
    // Stage 1: 比较逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            pattern_stage1 <= 0;
            match_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            data_stage1 <= data;
            pattern_stage1 <= pattern;
            match_stage1 <= (data == pattern);
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: 计数逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            match_stage2 <= match_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 计数器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_count <= 0;
        end else if (valid_stage2 && match_stage2) begin
            match_count <= match_count + 1;
        end
    end
    
    // 输出有效信号
    assign valid_out = valid_stage2;
    
endmodule