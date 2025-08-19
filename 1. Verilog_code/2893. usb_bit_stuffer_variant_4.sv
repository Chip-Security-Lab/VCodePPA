//SystemVerilog - IEEE 1364-2005
module usb_bit_stuffer(
    input wire clk_i,
    input wire rst_i,
    input wire bit_i,
    input wire valid_i,
    output reg bit_o,
    output reg valid_o,
    output reg stuffed_o
);
    localparam MAX_ONES = 6;
    
    // 寄存输入信号
    reg bit_i_reg;
    reg valid_i_reg;
    
    // 内部状态寄存器
    reg [2:0] ones_count;
    
    // 组合逻辑输出
    wire [2:0] next_ones_count;
    wire next_bit_o;
    wire next_valid_o;
    wire next_stuffed_o;
    
    // 将输入信号寄存，减少输入到第一级寄存器的延迟
    always @(posedge clk_i) begin
        if (rst_i) begin
            bit_i_reg <= 1'b0;
            valid_i_reg <= 1'b0;
        end else begin
            bit_i_reg <= bit_i;
            valid_i_reg <= valid_i;
        end
    end
    
    // 组合逻辑 - 计算连续1的数量
    assign next_ones_count = (!valid_i_reg) ? ones_count :
                             (bit_i_reg == 1'b0) ? 3'd0 :
                             (ones_count == MAX_ONES-1) ? 3'd0 :
                             ones_count + 1'b1;
    
    // 组合逻辑 - 生成输出比特
    assign next_bit_o = (!valid_i_reg) ? 1'b0 :
                         (ones_count == MAX_ONES-1 && bit_i_reg == 1'b1) ? 1'b0 :
                         bit_i_reg;
    
    // 组合逻辑 - 生成有效标志和填充标志
    assign next_valid_o = valid_i_reg;
    assign next_stuffed_o = (valid_i_reg && ones_count == MAX_ONES-1 && bit_i_reg == 1'b1) ? 1'b1 : 1'b0;
    
    // 时序逻辑部分 - 更新连续性计数器
    always @(posedge clk_i) begin
        if (rst_i) begin
            ones_count <= 3'd0;
        end else begin
            ones_count <= next_ones_count;
        end
    end
    
    // 时序逻辑部分 - 更新输出信号
    always @(posedge clk_i) begin
        if (rst_i) begin
            bit_o <= 1'b0;
            valid_o <= 1'b0;
            stuffed_o <= 1'b0;
        end else begin
            bit_o <= next_bit_o;
            valid_o <= next_valid_o;
            stuffed_o <= next_stuffed_o;
        end
    end
    
endmodule