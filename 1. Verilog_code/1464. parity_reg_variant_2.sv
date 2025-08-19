//SystemVerilog
module parity_reg(
    input clk, reset,
    input [7:0] data,
    input load,
    output reg [8:0] data_with_parity
);
    // 定义控制信号组合
    wire [1:0] ctrl;
    
    // 添加data_with_parity的缓冲寄存器用于减少扇出负载
    reg [8:0] data_with_parity_buf1;
    reg [8:0] data_with_parity_buf2;
    
    // 组合逻辑：将控制信号组合
    assign ctrl = {reset, load};
    
    // 合并所有posedge clk触发的always块
    always @(posedge clk) begin
        // 数据处理逻辑
        case(ctrl)
            2'b10, 2'b11: begin  // reset优先级最高
                data_with_parity <= 9'b0;
            end
            2'b01: begin  // load激活且reset未激活
                data_with_parity[7:0] <= data;
                data_with_parity[8] <= ^data;  // Parity bit
            end
            2'b00: begin  // 保持当前值
                data_with_parity <= data_with_parity;
            end
        endcase
        
        // 缓冲寄存器逻辑
        data_with_parity_buf1 <= data_with_parity;
        data_with_parity_buf2 <= data_with_parity_buf1;
    end
endmodule