module ITRC_EdgeDetect #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,    // 中断源输入
    output reg [WIDTH-1:0] int_out, // 同步输出
    output reg int_valid           // 中断有效标志
);
    reg [WIDTH-1:0] prev_state;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_state <= 0;
            int_out <= 0;
            int_valid <= 0;
        end else begin
            prev_state <= int_src;
            int_out <= (int_src ^ prev_state) & int_src; // 上升沿检测
            int_valid <= |int_out;
        end
    end
endmodule