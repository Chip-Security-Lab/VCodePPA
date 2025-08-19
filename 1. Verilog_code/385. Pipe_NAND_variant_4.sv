//SystemVerilog
// 顶层模块：管理增强型流水线的连接和信号流
module Pipe_NAND(
    input  wire        clk,
    input  wire        rst_n,    // 复位信号
    input  wire        valid_in, // 输入有效信号
    input  wire [15:0] a, b,
    output wire        valid_out, // 输出有效信号
    output wire [15:0] out
);
    // 四级流水线的状态和数据信号
    wire [15:0] a_stage1, b_stage1;
    wire [15:0] a_stage2, b_stage2;
    wire [15:0] partial_nand_stage3;
    wire        valid_stage1, valid_stage2, valid_stage3;
    
    // 实例化第一级流水线：输入寄存
    InputRegisterStage input_stage (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .a_in      (a),
        .b_in      (b),
        .valid_out (valid_stage1),
        .a_out     (a_stage1),
        .b_out     (b_stage1)
    );
    
    // 实例化第二级流水线：预处理阶段
    PreprocessStage preprocess_stage (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_stage1),
        .a_in      (a_stage1),
        .b_in      (b_stage1),
        .valid_out (valid_stage2),
        .a_out     (a_stage2),
        .b_out     (b_stage2)
    );
    
    // 实例化第三级流水线：计算NAND
    NANDStage nand_stage (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_stage2),
        .a_in      (a_stage2),
        .b_in      (b_stage2),
        .valid_out (valid_stage3),
        .nand_out  (partial_nand_stage3)
    );
    
    // 实例化第四级流水线：输出寄存
    OutputRegisterStage output_stage (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_stage3),
        .result_in (partial_nand_stage3),
        .valid_out (valid_out),
        .result    (out)
    );
    
endmodule

// 第一级流水线：输入寄存模块
module InputRegisterStage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [15:0] a_in, b_in,
    output reg         valid_out,
    output reg  [15:0] a_out, b_out
);
    // 寄存输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out     <= 16'b0;
            b_out     <= 16'b0;
            valid_out <= 1'b0;
        end else begin
            a_out     <= a_in;
            b_out     <= b_in;
            valid_out <= valid_in;
        end
    end
endmodule

// 第二级流水线：预处理阶段
module PreprocessStage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [15:0] a_in, b_in,
    output reg         valid_out,
    output reg  [15:0] a_out, b_out
);
    // 预处理数据 - 分割计算流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out     <= 16'b0;
            b_out     <= 16'b0;
            valid_out <= 1'b0;
        end else begin
            // 在这个阶段可以增加预处理逻辑
            // 这里只是传递数据，实际应用中可以添加更多计算
            a_out     <= a_in;
            b_out     <= b_in;
            valid_out <= valid_in;
        end
    end
endmodule

// 第三级流水线：NAND计算模块
module NANDStage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [15:0] a_in, b_in,
    output reg         valid_out,
    output reg  [15:0] nand_out
);
    // NAND操作分割为两部分：先计算AND，再取反
    reg [15:0] and_result;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= 16'b0;
            nand_out   <= 16'b0;
            valid_out  <= 1'b0;
        end else begin
            // 计算阶段：先进行AND操作
            and_result <= a_in & b_in;
            // 取反操作：在同一个时钟周期完成
            nand_out   <= ~(a_in & b_in);
            valid_out  <= valid_in;
        end
    end
endmodule

// 第四级流水线：输出寄存模块
module OutputRegisterStage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [15:0] result_in,
    output reg         valid_out,
    output reg  [15:0] result
);
    // 寄存输出数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result    <= 16'b0;
            valid_out <= 1'b0;
        end else begin
            result    <= result_in;
            valid_out <= valid_in;
        end
    end
endmodule