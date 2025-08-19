//SystemVerilog
module param_buffer #(
    parameter DATA_WIDTH = 16
)(
    input wire clk,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [DATA_WIDTH-1:0] subtrahend,  // 减数输入
    input wire load,
    input wire subtract_en,                   // 减法使能信号
    output reg [DATA_WIDTH-1:0] data_out
);
    // 注册所有输入信号，实现后向寄存器重定时
    reg [DATA_WIDTH-1:0] data_in_reg;
    reg [DATA_WIDTH-1:0] subtrahend_reg;
    reg load_reg;
    reg subtract_en_reg;
    
    // 输入信号寄存器化
    always @(posedge clk) begin
        data_in_reg <= data_in;
        subtrahend_reg <= subtrahend;
        load_reg <= load;
        subtract_en_reg <= subtract_en;
    end
    
    // 二进制补码减法算法的中间信号
    wire [DATA_WIDTH-1:0] complement;
    wire [DATA_WIDTH-1:0] sub_result;
    
    // 计算二进制补码 (取反加一)，使用已寄存器化的减数
    assign complement = ~subtrahend_reg + 1'b1;
    
    // 使用补码进行减法 (等效于加法)，使用已寄存器化的输入
    assign sub_result = data_in_reg + complement;
    
    // 输出寄存器更新逻辑，使用已寄存器化的控制信号
    always @(posedge clk) begin
        if (load_reg) begin
            if (subtract_en_reg)
                data_out <= sub_result;  // 执行减法运算
            else
                data_out <= data_in_reg; // 正常加载数据
        end
    end
endmodule