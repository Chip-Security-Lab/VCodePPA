//SystemVerilog
module multi_route_xnor1 (
    input  wire clk,     // 时钟输入用于流水线寄存器
    input  wire rst_n,   // 复位信号
    input  wire A,
    input  wire B, 
    input  wire C,
    output wire Y
);

    // 第一阶段 - 寄存输入信号
    reg A_stage1, B_stage1, C_stage1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_stage1 <= 1'b0;
            B_stage1 <= 1'b0;
            C_stage1 <= 1'b0;
        end else begin
            A_stage1 <= A;
            B_stage1 <= B;
            C_stage1 <= C;
        end
    end

    // 第二阶段 - 计算各输入对之间的XNOR基础操作
    wire a_xor_b_stage2, b_xor_c_stage2, a_xor_c_stage2;
    
    assign a_xor_b_stage2 = A_stage1 ^ B_stage1;  // A和B的XOR
    assign b_xor_c_stage2 = B_stage1 ^ C_stage1;  // B和C的XOR
    assign a_xor_c_stage2 = A_stage1 ^ C_stage1;  // A和C的XOR
    
    // 第二阶段寄存器
    reg a_xor_b_stage2_r, b_xor_c_stage2_r, a_xor_c_stage2_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_xor_b_stage2_r <= 1'b0;
            b_xor_c_stage2_r <= 1'b0;
            a_xor_c_stage2_r <= 1'b0;
        end else begin
            a_xor_b_stage2_r <= a_xor_b_stage2;
            b_xor_c_stage2_r <= b_xor_c_stage2;
            a_xor_c_stage2_r <= a_xor_c_stage2;
        end
    end
    
    // 第三阶段 - 计算XNOR结果
    wire xnor_ab_stage3, xnor_bc_stage3, xnor_ac_stage3;
    
    assign xnor_ab_stage3 = ~a_xor_b_stage2_r;  // A和B的XNOR
    assign xnor_bc_stage3 = ~b_xor_c_stage2_r;  // B和C的XNOR
    assign xnor_ac_stage3 = ~a_xor_c_stage2_r;  // A和C的XNOR
    
    // 第三阶段寄存器
    reg xnor_ab_stage3_r, xnor_bc_stage3_r, xnor_ac_stage3_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xnor_ab_stage3_r <= 1'b0;
            xnor_bc_stage3_r <= 1'b0;
            xnor_ac_stage3_r <= 1'b0;
        end else begin
            xnor_ab_stage3_r <= xnor_ab_stage3;
            xnor_bc_stage3_r <= xnor_bc_stage3;
            xnor_ac_stage3_r <= xnor_ac_stage3;
        end
    end
    
    // 第四阶段 - 计算AB与BC的与操作
    wire ab_and_bc_stage4;
    assign ab_and_bc_stage4 = xnor_ab_stage3_r & xnor_bc_stage3_r;
    
    // 第四阶段寄存器
    reg ab_and_bc_stage4_r, xnor_ac_stage4_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ab_and_bc_stage4_r <= 1'b0;
            xnor_ac_stage4_r <= 1'b0;
        end else begin
            ab_and_bc_stage4_r <= ab_and_bc_stage4;
            xnor_ac_stage4_r <= xnor_ac_stage3_r;
        end
    end
    
    // 第五阶段 - 最终与操作
    wire stage5_result;
    assign stage5_result = ab_and_bc_stage4_r & xnor_ac_stage4_r;
    
    // 输出寄存器
    reg Y_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y_r <= 1'b0;
        end else begin
            Y_r <= stage5_result;
        end
    end
    
    // 输出赋值
    assign Y = Y_r;

endmodule