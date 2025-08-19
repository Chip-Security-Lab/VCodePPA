//SystemVerilog
module xor_generate (
    input  wire        clk,      // 时钟信号
    input  wire        rst_n,    // 低电平有效复位信号
    input  wire [3:0]  a_in,     // 输入数据a
    input  wire [3:0]  b_in,     // 输入数据b
    output wire [3:0]  y_out     // 输出结果
);
    // 阶段间连接信号
    wire [3:0] a_stage1, b_stage1;
    wire [3:0] xor_result;
    
    // 实例化输入寄存器模块
    input_register input_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .a_in(a_in),
        .b_in(b_in),
        .a_out(a_stage1),
        .b_out(b_stage1)
    );
    
    // 实例化组合逻辑XOR计算模块
    xor_combinational xor_comb_inst (
        .a_in(a_stage1),
        .b_in(b_stage1),
        .xor_out(xor_result)
    );
    
    // 实例化输出寄存器模块
    output_register output_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .xor_in(xor_result),
        .y_out(y_out)
    );

endmodule

// 输入寄存器模块 - 仅包含时序逻辑
module input_register (
    input  wire        clk,      // 时钟信号
    input  wire        rst_n,    // 低电平有效复位信号
    input  wire [3:0]  a_in,     // 输入数据a
    input  wire [3:0]  b_in,     // 输入数据b
    output reg  [3:0]  a_out,    // 第一级流水线a输出
    output reg  [3:0]  b_out     // 第一级流水线b输出
);
    
    // 第一级流水线 - 注册输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out <= 4'b0;
            b_out <= 4'b0;
        end else begin
            a_out <= a_in;
            b_out <= b_in;
        end
    end
    
endmodule

// XOR组合逻辑模块 - 仅包含组合逻辑
module xor_combinational (
    input  wire [3:0]  a_in,     // 第一级流水线a输出
    input  wire [3:0]  b_in,     // 第一级流水线b输出
    output wire [3:0]  xor_out   // XOR计算结果
);
    
    // 计算XOR结果 - 拆分为两部分以减少逻辑深度
    assign xor_out[1:0] = a_in[1:0] ^ b_in[1:0];
    assign xor_out[3:2] = a_in[3:2] ^ b_in[3:2];
    
endmodule

// 输出寄存器模块 - 仅包含时序逻辑
module output_register (
    input  wire        clk,      // 时钟信号
    input  wire        rst_n,    // 低电平有效复位信号
    input  wire [3:0]  xor_in,   // XOR计算结果
    output reg  [3:0]  y_out     // 最终输出结果
);
    
    // 第二级流水线 - 注册XOR结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_out <= 4'b0;
        end else begin
            y_out <= xor_in;
        end
    end
    
endmodule