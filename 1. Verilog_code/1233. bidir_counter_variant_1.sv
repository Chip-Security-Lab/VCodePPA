//SystemVerilog
module bidir_counter #(parameter N = 4) (
    input wire clock, clear, load, up_down,
    input wire [N-1:0] data_in,
    output reg [N-1:0] count
);
    // 寄存输入信号以减少输入到第一级寄存器的延迟
    reg clear_reg, load_reg, up_down_reg;
    reg [N-1:0] data_in_reg;
    
    // 将控制信号组合成一个control信号
    wire [1:0] control;
    
    // 在时钟上升沿寄存所有输入信号
    always @(posedge clock) begin
        clear_reg <= clear;
        load_reg <= load;
        up_down_reg <= up_down;
        data_in_reg <= data_in;
    end
    
    // 使用寄存后的控制信号生成control
    assign control = {clear_reg, load_reg};
    
    // 主计数逻辑使用寄存后的信号
    always @(posedge clock) begin
        case(control)
            2'b10,
            2'b11: count <= {N{1'b0}};    // 清零优先级最高
            2'b01: count <= data_in_reg;   // 加载数据
            2'b00: count <= up_down_reg ? count + 1'b1 : count - 1'b1;  // 增减计数
            default: count <= count;       // 保持不变
        endcase
    end
endmodule