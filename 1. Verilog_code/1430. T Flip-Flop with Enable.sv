module t_ff_enable (
    input wire clk,
    input wire en,
    input wire t,
    output reg q
);
    always @(posedge clk) begin
        if (en)
            q <= t ? ~q : q;
    end
endmodule