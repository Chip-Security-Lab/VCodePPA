//SystemVerilog
module FastDiv(
    input clk,               // 时钟信号
    input rst_n,             // 复位信号，低电平有效
    
    input [15:0] a,          // 输入数据a
    input [15:0] b,          // 输入数据b
    input        valid_in,   // 输入数据有效信号
    output       ready_out,  // 模块准备接收新数据信号
    
    output [15:0] q,         // 结果数据
    output        valid_out, // 输出数据有效信号
    input         ready_in   // 下游模块准备接收数据信号
);

    // 内部寄存器和状态信号
    reg [15:0] a_reg, b_reg;
    reg [15:0] q_reg;
    reg busy;
    reg output_valid;
    
    // 计算用的中间信号
    wire [31:0] inv_b;
    wire [15:0] q_next;
    
    // 除法计算逻辑
    assign inv_b = 32'hFFFF_FFFF / b_reg;
    assign q_next = (inv_b * a_reg) >> 16;
    
    // 输出信号赋值
    assign q = q_reg;
    assign valid_out = output_valid;
    assign ready_out = !busy || (output_valid && ready_in);
    
    // 主状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 16'b0;
            b_reg <= 16'b0;
            q_reg <= 16'b0;
            busy <= 1'b0;
            output_valid <= 1'b0;
        end
        else begin
            // 处理输入握手
            if (!busy && valid_in) begin
                a_reg <= a;
                b_reg <= (b == 16'b0) ? 16'b1 : b; // 防止除零
                busy <= 1'b1;
            end
            
            // 处理计算和输出握手
            if (busy && !output_valid) begin
                q_reg <= q_next;
                output_valid <= 1'b1;
            end
            else if (output_valid && ready_in) begin
                output_valid <= 1'b0;
                busy <= 1'b0;
            end
        end
    end

endmodule