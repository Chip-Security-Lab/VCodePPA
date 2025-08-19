module dual_d_flip_flop (
    input wire clk,
    input wire rst_n,
    input wire d1,
    input wire d2,
    output reg q1,
    output reg q2
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q1 <= 1'b0;
            q2 <= 1'b0;
        end
        else begin
            q1 <= d1;
            q2 <= d2;
        end
    end
endmodule