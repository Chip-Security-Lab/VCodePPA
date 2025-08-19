//SystemVerilog
// 顶层模块
module xor2_4 (
    input  wire clk,    // 时钟输入
    input  wire rst_n,  // 复位信号
    input  wire A,      // 输入A
    input  wire B,      // 输入B
    output wire Y       // 输出Y
);
    // 内部连接信号
    wire stage1_a, stage1_b;   // 第一级寄存器输出
    wire stage2_xor;           // 第二级寄存器输出
    
    // 实例化输入寄存子模块
    input_register input_reg_inst (
        .clk    (clk),
        .rst_n  (rst_n),
        .A      (A),
        .B      (B),
        .A_reg  (stage1_a),
        .B_reg  (stage1_b)
    );
    
    // 实例化XOR运算子模块
    xor_operation xor_op_inst (
        .clk    (clk),
        .rst_n  (rst_n),
        .A_reg  (stage1_a),
        .B_reg  (stage1_b),
        .xor_out(stage2_xor)
    );
    
    // 实例化输出寄存子模块
    output_register output_reg_inst (
        .clk    (clk),
        .rst_n  (rst_n),
        .xor_in (stage2_xor),
        .Y      (Y)
    );
    
endmodule

// 输入寄存子模块
module input_register (
    input  wire clk,     // 时钟输入
    input  wire rst_n,   // 复位信号
    input  wire A,       // 原始输入A
    input  wire B,       // 原始输入B
    output reg  A_reg,   // 寄存后的A
    output reg  B_reg    // 寄存后的B
);
    
    // 第一级流水线 - 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg <= 1'b0;
            B_reg <= 1'b0;
        end else begin
            A_reg <= A;
            B_reg <= B;
        end
    end
    
endmodule

// XOR运算子模块
module xor_operation (
    input  wire clk,     // 时钟输入
    input  wire rst_n,   // 复位信号
    input  wire A_reg,   // 寄存后的A
    input  wire B_reg,   // 寄存后的B
    output reg  xor_out  // XOR运算结果
);
    
    // 第二级流水线 - XOR运算及结果寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_out <= 1'b0;
        end else begin
            xor_out <= A_reg ^ B_reg;
        end
    end
    
endmodule

// 输出寄存子模块
module output_register (
    input  wire clk,     // 时钟输入
    input  wire rst_n,   // 复位信号
    input  wire xor_in,  // XOR运算结果
    output reg  Y        // 最终输出
);
    
    // 输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= xor_in;
        end
    end
    
endmodule