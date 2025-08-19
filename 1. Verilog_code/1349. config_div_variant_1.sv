//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module config_div #(parameter MODE=0) (
    input wire clk, rst,
    output reg clk_out
);
    // 根据MODE参数选择分频比
    localparam DIV = MODE ? 8 : 16;
    // 针对最大分频值优化计数器位宽
    localparam CNT_WIDTH = $clog2(DIV);
    
    // 计数器寄存器
    reg [CNT_WIDTH-1:0] cnt;
    // 时钟输出寄存器
    reg clk_toggle_reg;
    
    // 计算下一计数值和最大值检测（移动到寄存器前）
    wire [CNT_WIDTH-1:0] next_cnt = (cnt == (DIV-1)) ? {CNT_WIDTH{1'b0}} : cnt + 1'b1;
    wire cnt_max = (cnt == DIV-1);
    
    // 计算下一时钟状态（移动到寄存器前）
    wire next_clk_out = cnt_max ? ~clk_toggle_reg : clk_toggle_reg;
    
    // 优化后的寄存器逻辑
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            // 复位逻辑
            cnt <= {CNT_WIDTH{1'b0}};
            clk_toggle_reg <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            // 直接更新计数器为已计算的下一值
            cnt <= next_cnt;
            
            // 更新输出时钟
            clk_toggle_reg <= next_clk_out;
            clk_out <= clk_toggle_reg;
        end
    end
endmodule