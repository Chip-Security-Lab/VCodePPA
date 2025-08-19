//SystemVerilog
module tristate_buffer (
    input  wire        clk,          // 系统时钟
    input  wire        rst_n,        // 异步复位，低电平有效
    input  wire [15:0] data_in,      // 输入数据总线
    input  wire        oe,           // 输出使能信号
    output wire [15:0] data_out      // 输出数据总线
);
    // 内部信号声明
    reg  [15:0] data_in_reg;         // 输入数据寄存器
    reg         oe_reg;              // 输出使能寄存器
    reg  [15:0] data_out_mux;        // 多路复用器输出寄存器
    
    // 第一级流水线：输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_in_reg <= 16'b0;
            oe_reg      <= 1'b0;
        end
        else begin
            data_in_reg <= data_in;
            oe_reg      <= oe;
        end
    end
    
    // 显式多路复用器结构
    always @(*) begin
        case (oe_reg)
            1'b1:    data_out_mux = data_in_reg;
            default: data_out_mux = 16'bz;
        endcase
    end
    
    // 输出赋值
    assign data_out = data_out_mux;

endmodule