//SystemVerilog
module LFSR_Shifter #(parameter WIDTH=8, TAPS=8'b10001110) (
    input clk, rst,
    output serial_out
);
    reg [WIDTH-1:0] lfsr_reg;
    reg out_bit_reg;
    
    // 组合逻辑部分
    wire [WIDTH-1:0] taps_masked;
    reg feedback_bit_stage1; // 流水线寄存器1
    wire [WIDTH-1:0] next_lfsr;
    wire next_out_bit;
    
    // 将复杂的反馈计算分为两阶段
    // 第一阶段: 应用掩码
    assign taps_masked = lfsr_reg & TAPS;
    
    // 第二阶段: 计算异或 (流水线化)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            feedback_bit_stage1 <= 1'b1;
        end else begin
            feedback_bit_stage1 <= ^taps_masked;
        end
    end
    
    // 计算下一个LFSR状态 (基于流水线寄存器的输出)
    assign next_lfsr = {lfsr_reg[WIDTH-2:0], feedback_bit_stage1};
    
    // 计算下一个输出位
    assign next_out_bit = lfsr_reg[WIDTH-1];
    
    // 主寄存器更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr_reg <= {WIDTH{1'b1}};
            out_bit_reg <= 1'b1;
        end else begin
            lfsr_reg <= next_lfsr;
            out_bit_reg <= next_out_bit;
        end
    end
    
    // 输出赋值
    assign serial_out = out_bit_reg;
    
endmodule