module not_gate_4bit_neg_edge (
    input wire clk,
    input wire [3:0] A,
    output reg [3:0] Y
);
    always @ (negedge clk) begin
        Y <= ~A;
    end
endmodule