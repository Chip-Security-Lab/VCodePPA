//SystemVerilog
module transparent_buffer (
    input wire clk,           // 时钟信号
    input wire rst_n,         // 复位信号
    input wire [7:0] data_in, // 输入数据
    input wire valid_in,      // 数据有效信号
    output wire ready_out,    // 准备接收信号
    output reg [7:0] data_out,// 输出数据
    output reg valid_out,     // 输出数据有效信号
    input wire ready_in       // 下游准备接收信号
);
    // 内部状态信号
    reg busy;

    // 当下游准备好接收时，表示可以接收新数据
    assign ready_out = !busy || ready_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
            valid_out <= 1'b0;
            busy <= 1'b0;
        end else begin
            if (ready_in) begin
                // 下游已接收数据，清除busy状态
                valid_out <= 1'b0;
                busy <= 1'b0;
            end
            
            if (valid_in && ready_out) begin
                // 接收新数据
                busy <= 1'b1;
                valid_out <= 1'b1;
                data_out <= data_in;
            end
        end
    end
endmodule