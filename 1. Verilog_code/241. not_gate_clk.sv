module not_gate_clk (
    input wire clk,
    input wire A,
    output reg Y
);
    always @ (posedge clk) begin
        Y <= ~A;
    end
endmodule