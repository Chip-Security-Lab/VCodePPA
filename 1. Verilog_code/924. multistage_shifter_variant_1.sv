//SystemVerilog
module multistage_shifter(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire [2:0] shift_amt,
    output reg [7:0] data_out
);
    // 寄存器化的数据通路，将长路径分段
    reg [7:0] stage0_reg, stage1_reg;
    reg [2:0] shift_amt_s0, shift_amt_s1, shift_amt_s2;
    
    // 阶段0：数据输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage0_reg <= 8'b0;
            shift_amt_s0 <= 3'b0;
        end else begin
            stage0_reg <= data_in;
            shift_amt_s0 <= shift_amt;
        end
    end
    
    // 阶段1：第一级移位操作（移0或1位）
    wire [7:0] stage0_shifted = shift_amt_s0[0] ? {stage0_reg[6:0], 1'b0} : stage0_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_reg <= 8'b0;
            shift_amt_s1 <= 3'b0;
        end else begin
            stage1_reg <= stage0_shifted;
            shift_amt_s1 <= shift_amt_s0;
        end
    end
    
    // 阶段2：第二级移位操作（移0或2位）
    wire [7:0] stage1_shifted = shift_amt_s1[1] ? {stage1_reg[5:0], 2'b00} : stage1_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_amt_s2 <= 3'b0;
            data_out <= 8'b0;
        end else begin
            shift_amt_s2 <= shift_amt_s1;
            // 阶段3：第三级移位操作（移0或4位）
            data_out <= shift_amt_s2[2] ? {stage1_shifted[3:0], 4'b0000} : stage1_shifted;
        end
    end
endmodule