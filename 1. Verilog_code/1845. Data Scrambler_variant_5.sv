//SystemVerilog
module data_scrambler #(parameter POLY_WIDTH = 7) (
    input  wire clk,
    input  wire reset,
    input  wire data_in,
    input  wire [POLY_WIDTH-1:0] polynomial,
    input  wire [POLY_WIDTH-1:0] initial_state,
    input  wire load_init,
    output wire data_out
);
    reg [POLY_WIDTH-1:0] lfsr_reg;
    reg feedback;
    
    // 优化的反馈计算 - 使用循环替代位掩码和异或运算，减少门延迟
    always @(*) begin
        feedback = 1'b0;
        for (integer i = 0; i < POLY_WIDTH; i = i + 1) begin
            if (polynomial[i])
                feedback = feedback ^ lfsr_reg[i];
        end
    end
    
    // 直接将数据与LFSR输出进行异或
    assign data_out = data_in ^ lfsr_reg[0];
    
    // 寄存器更新逻辑优化 - 减少复杂的位拼接操作
    always @(posedge clk) begin
        if (reset)
            lfsr_reg <= {POLY_WIDTH{1'b1}}; // 非零默认值
        else if (load_init)
            lfsr_reg <= initial_state;
        else begin
            // 将寄存器右移，将反馈位放入最高位
            lfsr_reg[POLY_WIDTH-2:0] <= lfsr_reg[POLY_WIDTH-1:1];
            lfsr_reg[POLY_WIDTH-1] <= feedback;
        end
    end
endmodule