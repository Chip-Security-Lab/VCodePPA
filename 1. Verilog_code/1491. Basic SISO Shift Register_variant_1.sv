//SystemVerilog
module siso_shift_reg #(parameter WIDTH = 8) (
    input wire clk, rst, data_in,
    input wire valid_in,         // 输入数据有效信号
    output wire data_out,
    output wire valid_out        // 输出数据有效信号
);
    // 主要流水线寄存器
    reg [WIDTH-1:0] shift_reg;
    
    // 流水线控制信号
    reg [WIDTH-1:0] valid_pipeline;
    
    integer i;
    
    always @(posedge clk) begin
        // 使用条件运算符替代if-else结构
        shift_reg <= rst ? {WIDTH{1'b0}} : {shift_reg[WIDTH-2:0], data_in};
        
        // 有效信号流水线控制
        valid_pipeline[0] <= rst ? 1'b0 : valid_in;
        for (i = 1; i < WIDTH; i = i + 1) begin
            valid_pipeline[i] <= rst ? 1'b0 : valid_pipeline[i-1];
        end
    end
    
    assign data_out = shift_reg[WIDTH-1];
    assign valid_out = valid_pipeline[WIDTH-1];
endmodule