//SystemVerilog
module d_ff_reset_enable (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire d,
    output reg q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 1'b0;  // 复位状态：无论en值如何都复位为0
        end
        else begin
            if (en) begin
                q <= d;  // 使能有效时，输出跟随输入d
            end
            else begin
                q <= q;  // 使能无效时，保持当前值
            end
        end
    end
endmodule