//SystemVerilog
module gray_ring_counter (
    input clk, rst_n,
    output reg [3:0] gray_out
);
    // 中间状态寄存器，用于前向寄存器重定时
    reg next_gray_0, next_gray_1, next_gray_2, next_gray_3;
    
    // 下一状态逻辑直接连接到输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_gray_3 <= 1'b0;
            next_gray_2 <= 1'b0;
            next_gray_1 <= 1'b0;
            next_gray_0 <= 1'b0;
            gray_out <= 4'b0001;
        end else begin
            next_gray_3 <= gray_out[0];
            next_gray_2 <= gray_out[3];
            next_gray_1 <= gray_out[2] ^ gray_out[0];
            next_gray_0 <= gray_out[1];
            gray_out[3] <= next_gray_3;
            gray_out[2] <= next_gray_2;
            gray_out[1] <= next_gray_1;
            gray_out[0] <= next_gray_0;
        end
    end
endmodule