module t_ff_async_reset (
    input wire clk,
    input wire rst_n,
    input wire t,
    output reg q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else
            q <= t ? ~q : q;
    end
endmodule