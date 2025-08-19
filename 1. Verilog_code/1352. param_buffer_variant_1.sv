//SystemVerilog
module param_buffer #(
    parameter DATA_WIDTH = 16
)(
    input wire clk,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire load,
    output reg [DATA_WIDTH-1:0] data_out
);
    // 移动寄存器到输入侧
    reg [DATA_WIDTH-1:0] data_in_reg;
    reg load_reg;
    
    // 寄存输入数据和控制信号
    always @(posedge clk) begin
        data_in_reg <= data_in;
        load_reg <= load;
    end
    
    // 使用时序逻辑替代组合逻辑产生输出
    always @(posedge clk) begin
        if (load_reg) begin
            data_out <= data_in_reg;
        end
    end
    
endmodule