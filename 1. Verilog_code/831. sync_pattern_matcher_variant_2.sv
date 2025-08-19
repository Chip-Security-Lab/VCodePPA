//SystemVerilog
module sync_pattern_matcher #(parameter WIDTH = 8) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in, pattern,
    output match_out
);

    // 实例化流水线比较器子模块
    pipelined_pattern_comparator #(WIDTH) u_comparator (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .pattern(pattern),
        .match_out(match_out)
    );

endmodule

module pipelined_pattern_comparator #(parameter WIDTH = 8) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in, pattern,
    output match_out
);

    // 流水线寄存器
    reg [WIDTH-1:0] data_stage1, pattern_stage1;
    reg [WIDTH-1:0] data_stage2, pattern_stage2;
    reg valid_stage1, valid_stage2;
    reg match_stage1, match_stage2;
    
    // 流水线控制信号
    wire stage1_ready, stage2_ready;
    assign stage1_ready = 1'b1; // 第一级始终准备好接收新数据
    assign stage2_ready = 1'b1; // 第二级始终准备好接收新数据
    
    // 第一级流水线：数据采样
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {WIDTH{1'b0}};
            pattern_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            pattern_stage1 <= pattern;
            valid_stage1 <= 1'b1;
        end
    end
    
    // 第二级流水线：模式比较
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {WIDTH{1'b0}};
            pattern_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
            match_stage1 <= 1'b0;
        end else if (stage2_ready) begin
            data_stage2 <= data_stage1;
            pattern_stage2 <= pattern_stage1;
            valid_stage2 <= valid_stage1;
            match_stage1 <= (data_stage1 == pattern_stage1);
        end
    end
    
    // 第三级流水线：结果输出
    reg match_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_stage2 <= 1'b0;
            match_stage3 <= 1'b0;
        end else begin
            match_stage2 <= match_stage1;
            match_stage3 <= match_stage2;
        end
    end
    
    // 输出赋值
    assign match_out = match_stage3;

endmodule