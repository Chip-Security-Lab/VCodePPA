//SystemVerilog
module PipelineMatcher #(parameter WIDTH=8) (
    input clk,
    input rst,  // 复位信号
    input valid_in,  // 输入有效信号
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] pattern,
    output reg valid_out,  // 输出有效信号
    output reg match
);
    // 第一级流水线寄存器
    reg [WIDTH-1:0] data_stage1;
    reg [WIDTH-1:0] pattern_stage1;
    reg valid_stage1;
    
    // 第二级流水线寄存器
    reg [WIDTH-1:0] difference_stage2;
    reg valid_stage2;
    
    // 中间组合逻辑信号
    wire [WIDTH-1:0] difference;
    wire [WIDTH:0] borrow;
    
    // 借位减法器 - 组合逻辑部分
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: borrow_subtractor
            assign difference[i] = data_stage1[i] ^ pattern_stage1[i] ^ borrow[i];
            assign borrow[i+1] = (~data_stage1[i] & pattern_stage1[i]) | 
                                 (~data_stage1[i] & borrow[i]) | 
                                 (pattern_stage1[i] & borrow[i]);
        end
    endgenerate
    
    // 第一级流水线 - 数据输入寄存
    always @(posedge clk) begin
        if (rst) begin
            data_stage1 <= {WIDTH{1'b0}};
        end else if (valid_in) begin
            data_stage1 <= data_in;
        end
    end
    
    // 第一级流水线 - 模式寄存
    always @(posedge clk) begin
        if (rst) begin
            pattern_stage1 <= {WIDTH{1'b0}};
        end else if (valid_in) begin
            pattern_stage1 <= pattern;
        end
    end
    
    // 第一级流水线 - 有效信号传递
    always @(posedge clk) begin
        if (rst) begin
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线 - 差值计算结果寄存
    always @(posedge clk) begin
        if (rst) begin
            difference_stage2 <= {WIDTH{1'b0}};
        end else if (valid_stage1) begin
            difference_stage2 <= difference;
        end
    end
    
    // 第二级流水线 - 有效信号传递
    always @(posedge clk) begin
        if (rst) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线 - 匹配判断
    always @(posedge clk) begin
        if (rst) begin
            match <= 1'b0;
        end else if (valid_stage2) begin
            match <= (difference_stage2 == {WIDTH{1'b0}});
        end
    end
    
    // 第三级流水线 - 输出有效信号生成
    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_stage2;
        end
    end
endmodule