//SystemVerilog
// 顶层模块
module xor2_13 #(
    parameter PIPELINE_STAGES = 0,   // 可配置流水线级数
    parameter DRIVE_STRENGTH = 1     // 驱动强度参数
) (
    input  wire clk,     // 时钟信号，用于流水线寄存器
    input  wire rst_n,   // 复位信号，用于流水线寄存器
    input  wire A, B,    // 输入信号
    output wire Y        // 输出信号
);
    // 内部连线
    wire buffered_a, buffered_b;
    wire xor_result;
    
    // 实例化输入处理模块
    xor2_13_input_stage input_stage_inst (
        .A(A),
        .B(B),
        .A_buf(buffered_a),
        .B_buf(buffered_b)
    );
    
    // 实例化计算核心模块
    xor2_13_compute_core #(
        .PIPELINE_STAGES(PIPELINE_STAGES)
    ) compute_core_inst (
        .clk(clk),
        .rst_n(rst_n),
        .A(buffered_a),
        .B(buffered_b),
        .Y(xor_result)
    );
    
    // 实例化输出处理模块
    xor2_13_output_stage #(
        .DRIVE_STRENGTH(DRIVE_STRENGTH)
    ) output_stage_inst (
        .data_in(xor_result),
        .data_out(Y)
    );
    
endmodule

// 输入处理模块 - 负责输入信号的缓冲和调节
module xor2_13_input_stage (
    input  wire A, B,
    output wire A_buf, B_buf
);
    // 输入电平转换和阻抗匹配
    buf #(1, 2) buffer_a (A_buf, A); // 调整上升和下降延迟
    buf #(1, 2) buffer_b (B_buf, B);
endmodule

// 计算核心模块 - 基于流水线参数实现异或逻辑
module xor2_13_compute_core #(
    parameter PIPELINE_STAGES = 0
) (
    input  wire clk,
    input  wire rst_n,
    input  wire A, B,
    output wire Y
);
    generate
        if (PIPELINE_STAGES == 0) begin : no_pipeline
            // 无流水线情况下的直接异或实现
            xor2_13_logic_unit logic_unit (
                .A(A),
                .B(B),
                .Y(Y)
            );
        end
        else if (PIPELINE_STAGES == 1) begin : single_stage_pipeline
            // 单级流水线实现
            wire xor_combo;
            reg  y_reg;
            
            xor2_13_logic_unit logic_unit (
                .A(A),
                .B(B),
                .Y(xor_combo)
            );
            
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    y_reg <= 1'b0;
                else
                    y_reg <= xor_combo;
            end
            
            assign Y = y_reg;
        end
        else begin : multi_stage_pipeline
            // 多级流水线实现（这里示范两级，可扩展）
            wire xor_combo;
            reg  stage1_reg;
            reg  stage2_reg;
            
            xor2_13_logic_unit logic_unit (
                .A(A),
                .B(B),
                .Y(xor_combo)
            );
            
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    stage1_reg <= 1'b0;
                    stage2_reg <= 1'b0;
                end
                else begin
                    stage1_reg <= xor_combo;
                    stage2_reg <= stage1_reg;
                end
            end
            
            assign Y = stage2_reg;
        end
    endgenerate
endmodule

// 异或逻辑单元 - 基本计算单元
module xor2_13_logic_unit (
    input  wire A, B,
    output wire Y
);
    // 优化的异或实现，使用基本门而不是运算符
    wire a_inv, b_inv, and1, and2;
    
    not not_a (a_inv, A);
    not not_b (b_inv, B);
    
    and and_a_binv (and1, A, b_inv);
    and and_ainv_b (and2, a_inv, B);
    
    or or_result (Y, and1, and2);
endmodule

// 输出处理模块 - 负责输出信号的缓冲和调节
module xor2_13_output_stage #(
    parameter DRIVE_STRENGTH = 1
) (
    input  wire data_in,
    output wire data_out
);
    generate
        if (DRIVE_STRENGTH == 1) begin : low_drive
            // 标准驱动强度
            buf buffer_out (data_out, data_in);
        end
        else if (DRIVE_STRENGTH == 2) begin : medium_drive
            // 中等驱动强度
            bufif1 #(2, 3) tri_buffer (data_out, data_in, 1'b1);
        end
        else begin : high_drive
            // 高驱动强度
            bufif1 #(1, 2) tri_buffer_1 (data_out, data_in, 1'b1);
            bufif1 #(1, 2) tri_buffer_2 (data_out, data_in, 1'b1);
        end
    endgenerate
endmodule