//SystemVerilog
module multistage_shifter(
    input wire clk,          // 添加时钟信号用于流水线寄存器
    input wire rst_n,        // 添加复位信号
    input wire [7:0] data_in,
    input wire [2:0] shift_amt,
    output wire [7:0] data_out
);
    // 流水线寄存器信号声明
    reg [7:0] stage0_data_r, stage1_data_r, stage2_data_r;
    reg [2:0] shift_amt_r1, shift_amt_r2, shift_amt_r3;
    
    //===== 第一级：移位控制寄存和第一级移位 =====
    // 寄存输入信号和移位控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage0_data_r <= 8'h0;
            shift_amt_r1 <= 3'h0;
        end else begin
            stage0_data_r <= data_in;
            shift_amt_r1 <= shift_amt;
        end
    end
    
    //===== 第二级：执行0或1位移位 =====
    wire [7:0] stage0_shifted = shift_amt_r1[0] ? {stage0_data_r[6:0], 1'b0} : stage0_data_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data_r <= 8'h0;
            shift_amt_r2 <= 3'h0;
        end else begin
            stage1_data_r <= stage0_shifted;
            shift_amt_r2 <= shift_amt_r1;
        end
    end
    
    //===== 第三级：执行0或2位移位 =====
    wire [7:0] stage1_shifted = shift_amt_r2[1] ? {stage1_data_r[5:0], 2'b00} : stage1_data_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data_r <= 8'h0;
            shift_amt_r3 <= 3'h0;
        end else begin
            stage2_data_r <= stage1_shifted;
            shift_amt_r3 <= shift_amt_r2;
        end
    end
    
    //===== 第四级：执行0或4位移位并输出 =====
    // 最终移位输出
    assign data_out = shift_amt_r3[2] ? {stage2_data_r[3:0], 4'b0000} : stage2_data_r;
    
endmodule