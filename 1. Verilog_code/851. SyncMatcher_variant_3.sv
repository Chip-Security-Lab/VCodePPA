//SystemVerilog
module SyncMatcher #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] data_in, pattern,
    output reg match
);
    // 增加流水线寄存器
    reg [1:0] ctrl_stage1;
    reg [WIDTH-1:0] data_in_stage1, pattern_stage1;
    reg [WIDTH-1:0] data_in_stage2, pattern_stage2;
    reg comparison_result_stage2;
    reg en_stage1, en_stage2;
    
    // 第一级流水线 - 寄存控制信号和输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_stage1 <= 2'b10;
            data_in_stage1 <= {WIDTH{1'b0}};
            pattern_stage1 <= {WIDTH{1'b0}};
            en_stage1 <= 1'b0;
        end else begin
            ctrl_stage1 <= {!rst_n, en};
            data_in_stage1 <= data_in;
            pattern_stage1 <= pattern;
            en_stage1 <= en;
        end
    end
    
    // 第二级流水线 - 进行比较操作的一部分
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage2 <= {WIDTH{1'b0}};
            pattern_stage2 <= {WIDTH{1'b0}};
            en_stage2 <= 1'b0;
        end else begin
            data_in_stage2 <= data_in_stage1;
            pattern_stage2 <= pattern_stage1;
            en_stage2 <= en_stage1;
        end
    end
    
    // 第二级流水线 - 完成比较操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comparison_result_stage2 <= 1'b0;
        end else if (en_stage2) begin
            comparison_result_stage2 <= (data_in_stage2 == pattern_stage2);
        end
    end
    
    // 第三级流水线 - 最终输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match <= 1'b0;
        end else if (en_stage2) begin
            match <= comparison_result_stage2;
        end
    end
endmodule