//SystemVerilog
module SyncMatcher #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] data_in, pattern,
    output reg match_out,
    // 流水线控制信号
    input valid_in,
    output reg valid_out,
    input ready_in,
    output reg ready_out
);
    // 流水线寄存器 - 第一级
    reg [WIDTH-1:0] data_stage1, pattern_stage1;
    reg valid_stage1;
    reg compare_result;
    
    // 流水线寄存器 - 第二级
    reg match_stage2;
    reg valid_stage2;
    
    // 准备接收新数据
    always @(*) begin
        ready_out = !valid_stage1 || (valid_stage1 && ready_in);
    end
    
    // 第一级流水线 - 数据锁存和比较
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {WIDTH{1'b0}};
            pattern_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
            compare_result <= 1'b0;
        end else begin
            if (ready_out && en && valid_in) begin
                data_stage1 <= data_in;
                pattern_stage1 <= pattern;
                valid_stage1 <= 1'b1;
                compare_result <= (data_in == pattern);
            end else if (ready_in && valid_stage1) begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 第二级流水线 - 结果锁存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1 && ready_in) begin
                match_stage2 <= compare_result;
                valid_stage2 <= 1'b1;
            end else if (valid_stage2 && ready_in) begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 输出赋值
    always @(*) begin
        match_out = match_stage2;
        valid_out = valid_stage2;
    end
endmodule