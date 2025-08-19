//SystemVerilog
module or_gate_2input_8bit (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    output reg [7:0] y
);
    // 输入寄存器
    reg [7:0] a_reg;
    reg [7:0] b_reg;
    
    // 结果寄存器
    reg [3:0] or_result_low;
    reg [3:0] or_result_high;
    reg [7:0] or_result;
    reg [7:0] or_result_prev;
    
    // 使能信号
    reg update_output;
    
    // 输入寄存器 A - 低位部分
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg[3:0] <= 4'b0;
        end else begin
            a_reg[3:0] <= a[3:0];
        end
    end
    
    // 输入寄存器 A - 高位部分
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg[7:4] <= 4'b0;
        end else begin
            a_reg[7:4] <= a[7:4];
        end
    end
    
    // 输入寄存器 B - 低位部分
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_reg[3:0] <= 4'b0;
        end else begin
            b_reg[3:0] <= b[3:0];
        end
    end
    
    // 输入寄存器 B - 高位部分
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_reg[7:4] <= 4'b0;
        end else begin
            b_reg[7:4] <= b[7:4];
        end
    end
    
    // OR运算 - 低4位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            or_result_low <= 4'b0;
        end else begin
            or_result_low <= a_reg[3:0] | b_reg[3:0];
        end
    end
    
    // OR运算 - 高4位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            or_result_high <= 4'b0;
        end else begin
            or_result_high <= a_reg[7:4] | b_reg[7:4];
        end
    end
    
    // 合并OR结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            or_result <= 8'b0;
        end else begin
            or_result <= {or_result_high, or_result_low};
        end
    end
    
    // 存储前一结果并计算更新使能信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            or_result_prev <= 8'b0;
            update_output <= 1'b0;
        end else begin
            or_result_prev <= or_result;
            update_output <= (or_result_prev != or_result);
        end
    end
    
    // 更新输出，仅在结果变化时
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 8'b0;
        end else if (update_output) begin
            y <= or_result;
        end
    end
    
endmodule