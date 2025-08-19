//SystemVerilog
module d_flip_flop (
    input wire clk,
    input wire d,
    output reg q
);
    // Directly register the output
    always @(posedge clk) begin
        q <= d;
    end
endmodule