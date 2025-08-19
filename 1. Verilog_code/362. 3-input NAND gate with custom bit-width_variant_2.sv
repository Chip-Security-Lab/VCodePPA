//SystemVerilog
`timescale 1ns / 1ps

// 顶层模块
module nand3_4 (
    input  wire        clk,      // Clock input
    input  wire        rst_n,    // Active low reset
    input  wire [3:0]  A,        // First input operand
    input  wire [3:0]  B,        // Second input operand
    input  wire [3:0]  C,        // Third input operand
    input  wire        valid_in, // Input valid signal
    output wire        ready_in, // Input ready signal
    output wire [3:0]  Y,        // Result output
    output wire        valid_out,// Output valid signal
    input  wire        ready_out // Output ready signal
);

    // 阶段控制信号
    wire stage1_valid, stage2_valid, stage3_valid;
    wire stage1_ready, stage2_ready, stage3_ready;
    
    // 阶段数据信号
    wire [3:0] A_reg, B_reg, C_reg;
    wire [3:0] AB_and;
    wire [3:0] Y_reg;
    
    // 反压控制子模块
    backpressure_controller bp_ctrl (
        .stage3_valid(stage3_valid),
        .stage2_valid(stage2_valid),
        .stage1_valid(stage1_valid),
        .ready_out(ready_out),
        .stage3_ready(stage3_ready),
        .stage2_ready(stage2_ready),
        .stage1_ready(stage1_ready),
        .ready_in(ready_in)
    );
    
    // 第一阶段子模块 - 输入寄存
    stage1_input_register stage1 (
        .clk(clk),
        .rst_n(rst_n),
        .A(A),
        .B(B),
        .C(C),
        .valid_in(valid_in),
        .ready_in(ready_in),
        .stage1_ready(stage1_ready),
        .A_reg(A_reg),
        .B_reg(B_reg),
        .C_reg(C_reg),
        .stage1_valid(stage1_valid)
    );
    
    // 第二阶段子模块 - 执行第一步计算
    stage2_and_compute stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .A_reg(A_reg),
        .B_reg(B_reg),
        .stage1_valid(stage1_valid),
        .stage1_ready(stage1_ready),
        .stage2_ready(stage2_ready),
        .AB_and(AB_and),
        .stage2_valid(stage2_valid)
    );
    
    // 第三阶段子模块 - 完成计算
    stage3_nand_complete stage3 (
        .clk(clk),
        .rst_n(rst_n),
        .AB_and(AB_and),
        .C_reg(C_reg),
        .stage2_valid(stage2_valid),
        .stage2_ready(stage2_ready),
        .stage3_ready(stage3_ready),
        .Y_reg(Y_reg),
        .stage3_valid(stage3_valid)
    );
    
    // 输出连接
    assign valid_out = stage3_valid;
    assign Y = Y_reg;

endmodule

// 反压控制子模块
module backpressure_controller (
    input  wire stage3_valid,
    input  wire stage2_valid,
    input  wire stage1_valid,
    input  wire ready_out,
    output wire stage3_ready,
    output wire stage2_ready,
    output wire stage1_ready,
    output wire ready_in
);
    // 反压处理逻辑
    assign stage3_ready = ready_out;
    assign stage2_ready = ~stage3_valid || stage3_ready;
    assign stage1_ready = ~stage2_valid || stage2_ready;
    assign ready_in = ~stage1_valid || stage1_ready;
endmodule

// 第一阶段子模块 - 输入寄存
module stage1_input_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  A,
    input  wire [3:0]  B,
    input  wire [3:0]  C,
    input  wire        valid_in,
    input  wire        ready_in,
    input  wire        stage1_ready,
    output reg  [3:0]  A_reg,
    output reg  [3:0]  B_reg,
    output reg  [3:0]  C_reg,
    output reg         stage1_valid
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg <= 4'b0;
            B_reg <= 4'b0;
            C_reg <= 4'b0;
            stage1_valid <= 1'b0;
        end else if (valid_in && ready_in) begin
            A_reg <= A;
            B_reg <= B;
            C_reg <= C;
            stage1_valid <= 1'b1;
        end else if (stage1_ready) begin
            stage1_valid <= 1'b0;
        end
    end
endmodule

// 第二阶段子模块 - 执行第一步计算
module stage2_and_compute (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  A_reg,
    input  wire [3:0]  B_reg,
    input  wire        stage1_valid,
    input  wire        stage1_ready,
    input  wire        stage2_ready,
    output reg  [3:0]  AB_and,
    output reg         stage2_valid
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            AB_and <= 4'b0;
            stage2_valid <= 1'b0;
        end else if (stage1_valid && stage1_ready) begin
            AB_and <= A_reg & B_reg;
            stage2_valid <= 1'b1;
        end else if (stage2_ready) begin
            stage2_valid <= 1'b0;
        end
    end
endmodule

// 第三阶段子模块 - 完成计算
module stage3_nand_complete (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  AB_and,
    input  wire [3:0]  C_reg,
    input  wire        stage2_valid,
    input  wire        stage2_ready,
    input  wire        stage3_ready,
    output reg  [3:0]  Y_reg,
    output reg         stage3_valid
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y_reg <= 4'b0;
            stage3_valid <= 1'b0;
        end else if (stage2_valid && stage2_ready) begin
            Y_reg <= ~(AB_and & C_reg);
            stage3_valid <= 1'b1;
        end else if (stage3_ready) begin
            stage3_valid <= 1'b0;
        end
    end
endmodule