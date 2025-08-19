//SystemVerilog IEEE 1364-2005
module xor_gate_level(
    input wire a,
    input wire b,
    output wire y
);
    // 流水线级寄存器
    reg stage1_a, stage1_b;
    reg stage1_a_inv, stage1_b_inv;
    reg stage2_path1, stage2_path2;
    
    // 内部连接信号
    wire a_inverted, b_inverted;
    wire and_path1, and_path2;
    
    // 时钟和复位信号 (添加以支持流水线)
    wire clk, rst_n;
    
    // 第一级：输入寄存和反相处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 1'b0;
            stage1_b <= 1'b0;
            stage1_a_inv <= 1'b1;
            stage1_b_inv <= 1'b1;
        end else begin
            stage1_a <= a;
            stage1_b <= b;
            stage1_a_inv <= ~a;
            stage1_b_inv <= ~b;
        end
    end
    
    // 第二级：AND计算和寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_path1 <= 1'b0;
            stage2_path2 <= 1'b0;
        end else begin
            stage2_path1 <= stage1_a & stage1_b_inv;    // a AND (NOT b)
            stage2_path2 <= stage1_a_inv & stage1_b;    // (NOT a) AND b
        end
    end
    
    // 第三级：最终OR操作 (组合逻辑输出)
    assign y = stage2_path1 | stage2_path2;
    
    // 时钟生成器模块实例化
    clock_manager clk_mgr (
        .clk_out(clk),
        .rst_n_out(rst_n)
    );
endmodule

//SystemVerilog IEEE 1364-2005
module clock_manager (
    output reg clk_out,
    output reg rst_n_out
);
    // 时钟和复位生成逻辑
    initial begin
        clk_out = 1'b0;
        rst_n_out = 1'b0;
        #10 rst_n_out = 1'b1;
    end
    
    // 生成时钟
    always #5 clk_out = ~clk_out;
endmodule