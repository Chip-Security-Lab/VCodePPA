//SystemVerilog
module shadow_reg_double_buf #(parameter WIDTH=8) (
    input clk, swap,
    input [WIDTH-1:0] update_data,
    output reg [WIDTH-1:0] active_data
);
    reg [WIDTH-1:0] buffer_reg;
    wire [WIDTH-1:0] complement_update_data; // 新增的信号

    assign complement_update_data = ~update_data + 1'b1; // 计算补码

    always @(posedge clk) begin
        active_data <= swap ? buffer_reg : active_data;
        buffer_reg <= swap ? buffer_reg : complement_update_data; // 使用补码加法实现减法
    end
endmodule