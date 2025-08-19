//SystemVerilog
module dyn_mode_shifter (
    input wire clk,              // 时钟信号
    input wire rst_n,            // 复位信号，低电平有效
    
    // 输入接口 - Valid-Ready握手协议
    input wire [15:0] data_in,   // 输入数据
    input wire [3:0] shift_in,   // 移位量
    input wire [1:0] mode_in,    // 00-逻辑左 01-算术右 10-循环
    input wire valid_in,         // 输入有效信号
    output wire ready_in,        // 输入就绪信号
    
    // 输出接口 - Valid-Ready握手协议
    output reg [15:0] data_out,  // 输出数据
    output reg valid_out,        // 输出有效信号
    input wire ready_out         // 输出就绪信号
);

    // 内部信号
    reg busy;
    wire process_data;
    
    // 握手逻辑
    assign ready_in = !busy || (valid_out && ready_out);
    assign process_data = valid_in && ready_in;
    
    // 处理逻辑和状态管理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            valid_out <= 1'b0;
            data_out <= 16'b0;
        end else begin
            if (process_data) begin
                busy <= 1'b1;
                valid_out <= 1'b1;
                
                // 移位器逻辑
                case (mode_in)
                    2'b00: data_out <= data_in << shift_in;
                    2'b01: data_out <= $signed(data_in) >>> shift_in;
                    2'b10: data_out <= (data_in << shift_in) | (data_in >> (16 - shift_in));
                    default: data_out <= data_in;
                endcase
            end
            
            // 输出握手完成时清除valid
            if (valid_out && ready_out) begin
                valid_out <= 1'b0;
                busy <= 1'b0;
            end
        end
    end

endmodule