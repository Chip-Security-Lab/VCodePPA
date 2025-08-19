//SystemVerilog
module nesting_ismu(
    input clk, rst,
    input [7:0] intr_src,
    input [7:0] intr_enable,
    input [7:0] intr_priority,
    input [2:0] current_level,
    output reg [2:0] intr_level,
    output reg intr_active
);
    // 注册输入信号以减少输入到第一级寄存器的延迟
    reg [7:0] intr_src_reg;
    reg [7:0] intr_enable_reg;
    reg [7:0] intr_priority_reg;
    reg [2:0] current_level_reg;
    
    // 将组合逻辑放在寄存器之后
    wire [7:0] active_src;
    wire [2:0] max_level;
    wire has_active_intr;
    
    // 输入信号寄存化
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            intr_src_reg <= 8'd0;
            intr_enable_reg <= 8'd0;
            intr_priority_reg <= 8'd0;
            current_level_reg <= 3'd0;
        end else begin
            intr_src_reg <= intr_src;
            intr_enable_reg <= intr_enable;
            intr_priority_reg <= intr_priority;
            current_level_reg <= current_level;
        end
    end
    
    // 移动到寄存器后的组合逻辑
    assign active_src = intr_src_reg & intr_enable_reg;
    
    assign max_level = (active_src[7] & intr_priority_reg[7] > current_level_reg) ? 3'd7 :
                       (active_src[6] & intr_priority_reg[6] > current_level_reg) ? 3'd6 :
                       (active_src[5] & intr_priority_reg[5] > current_level_reg) ? 3'd5 :
                       (active_src[4] & intr_priority_reg[4] > current_level_reg) ? 3'd4 :
                       (active_src[3] & intr_priority_reg[3] > current_level_reg) ? 3'd3 :
                       (active_src[2] & intr_priority_reg[2] > current_level_reg) ? 3'd2 :
                       (active_src[1] & intr_priority_reg[1] > current_level_reg) ? 3'd1 :
                       (active_src[0] & intr_priority_reg[0] > current_level_reg) ? 3'd0 : 3'd0;
                       
    assign has_active_intr = |active_src && (max_level > current_level_reg);
    
    // 输出寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            intr_level <= 3'd0;
            intr_active <= 1'b0;
        end else begin
            intr_active <= has_active_intr;
            intr_level <= max_level;
        end
    end
    
endmodule