//SystemVerilog
module multi_route_xnor1 (
    input  wire clk,     // 时钟信号
    input  wire rst_n,   // 复位信号，低电平有效
    input  wire A,       // 输入信号 A
    input  wire B,       // 输入信号 B
    input  wire C,       // 输入信号 C
    output reg  Y        // 输出信号 Y
);

    // 内部信号声明 - 第一级组合逻辑结果
    wire xnor_ab;        // A与B的XNOR结果
    wire xnor_bc;        // B与C的XNOR结果
    wire xnor_ac;        // A与C的XNOR结果
    
    // 第一流水线级寄存器
    reg xnor_ab_r;
    reg xnor_bc_r;
    reg xnor_ac_r;
    
    // 第二流水线级 - 最终结果寄存器
    reg result_r;
    
    // 为高扇出信号添加缓冲寄存器
    reg result_r_buf1;
    reg result_r_buf2;
    
    // B信号的缓冲寄存器(B0有较高扇出)
    reg B_buf1, B_buf2;

    // 第一级组合逻辑 - 计算各对输入的XNOR结果
    assign xnor_ab = ~(A ^ B_buf1);  // A和B的XNOR结果，使用B的缓冲
    assign xnor_bc = ~(B_buf2 ^ C);  // B和C的XNOR结果，使用B的缓冲
    assign xnor_ac = ~(A ^ C);       // A和C的XNOR结果

    // 流水线寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            // 复位所有流水线寄存器
            xnor_ab_r <= 1'b0;
            xnor_bc_r <= 1'b0;
            xnor_ac_r <= 1'b0;
            result_r  <= 1'b0;
            
            // 复位缓冲寄存器
            result_r_buf1 <= 1'b0;
            result_r_buf2 <= 1'b0;
            B_buf1 <= 1'b0;
            B_buf2 <= 1'b0;
            
            Y <= 1'b0;
        end else begin
            // B信号缓冲，分散扇出负载
            B_buf1 <= B;
            B_buf2 <= B;
            
            // 第一级流水线 - 保存XNOR结果
            xnor_ab_r <= xnor_ab;
            xnor_bc_r <= xnor_bc;
            xnor_ac_r <= xnor_ac;
            
            // 第二级流水线 - 计算最终的与运算结果
            result_r <= xnor_ab_r & xnor_bc_r & xnor_ac_r;
            
            // result_r的缓冲寄存器，分散扇出负载
            result_r_buf1 <= result_r;
            result_r_buf2 <= result_r;
            
            // 使用缓冲后的result_r信号驱动输出
            Y <= result_r_buf1;
        end
    end

endmodule