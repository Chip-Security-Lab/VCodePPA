module FSM_Sub(
    input clk,
    input start,
    input [7:0] A,
    input [7:0] B,
    output reg done,
    output reg [7:0] res
);

    always @(posedge clk) begin
        if (start) begin
            res <= A - B;
            done <= 1'b1;
        end else begin
            res <= res;
            done <= 1'b0;
        end
    end
endmodule