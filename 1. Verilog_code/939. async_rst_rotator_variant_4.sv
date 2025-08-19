//SystemVerilog
module async_rst_rotator (
    input clk, arst,
    input [7:0] data_in,
    input [2:0] shift,
    input valid,        // 替代原来的 en 信号，表示输入数据有效
    output ready,       // 新增信号，表示模块准备好接收数据
    output reg [7:0] data_out,
    output reg data_out_valid  // 新增信号，表示输出数据有效
);

// 内部状态信号
reg busy;

// ready信号生成 - 当模块不忙时就可以接收新数据
assign ready = !busy;

// 处理状态和数据
always @(posedge clk or posedge arst) begin
    if (arst) begin
        data_out <= 8'b0;
        data_out_valid <= 1'b0;
        busy <= 1'b0;
    end else begin
        if (valid && ready) begin
            // 有效握手，处理数据
            data_out <= (data_in << shift) | (data_in >> (8 - shift));
            data_out_valid <= 1'b1;
            busy <= 1'b1;  // 开始处理，标记为忙
        end else if (busy) begin
            // 完成处理，准备接收下一个数据
            busy <= 1'b0;
            data_out_valid <= 1'b0;
        end
    end
end

endmodule