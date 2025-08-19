module d_ff_reset_enable (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire d,
    output reg q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else if (en)
            q <= d;
    end
endmodule