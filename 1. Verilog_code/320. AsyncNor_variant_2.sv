//SystemVerilog
module AsyncNor(
    input clk,
    input rst,
    input a,
    input b,
    output reg y
);
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            y <= 1'b0;
        end else begin
            y <= ~(a | b);
        end
    end
endmodule