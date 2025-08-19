//SystemVerilog
//IEEE 1364-2005 Verilog标准
module binary_freq_div #(parameter WIDTH = 4) (
    input wire clk_in,
    input wire rst_n,
    output wire clk_out
);
    // 将计数器分成两部分以增加流水线深度
    reg [WIDTH/2-1:0] count_low_stage1;
    reg [WIDTH-WIDTH/2-1:0] count_high_stage2;
    
    // 进位信号
    reg carry_stage1, carry_stage2;
    
    // 输出寄存器以提高最大频率
    reg clk_out_reg_stage3;
    
    // 第一流水线级 - 低位计数
    always @(posedge clk_in) begin
        if (!rst_n) begin
            count_low_stage1 <= {(WIDTH/2){1'b0}};
            carry_stage1 <= 1'b0;
        end
        else begin
            {carry_stage1, count_low_stage1} <= count_low_stage1 + 1'b1;
        end
    end
    
    // 第二流水线级 - 高位计数
    always @(posedge clk_in) begin
        if (!rst_n) begin
            count_high_stage2 <= {(WIDTH-WIDTH/2){1'b0}};
            carry_stage2 <= 1'b0;
        end
        else begin
            if (carry_stage1)
                {carry_stage2, count_high_stage2} <= count_high_stage2 + 1'b1;
        end
    end
    
    // 第三流水线级 - 输出寄存
    always @(posedge clk_in) begin
        if (!rst_n)
            clk_out_reg_stage3 <= 1'b0;
        else
            clk_out_reg_stage3 <= count_high_stage2[WIDTH-WIDTH/2-1];
    end
    
    // 输出赋值
    assign clk_out = clk_out_reg_stage3;
endmodule