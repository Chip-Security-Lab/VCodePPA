//SystemVerilog
module Sync_XNOR(
    input clk,
    input [7:0] sig_a, sig_b,
    output [7:0] q
);
    wire [7:0] xnor_result;
    
    // Instantiate combinational logic module
    XNOR_Combo xnor_combo_inst (
        .a(sig_a),
        .b(sig_b),
        .result(xnor_result)
    );
    
    // Instantiate sequential logic module
    XNOR_Seq xnor_seq_inst (
        .clk(clk),
        .d(xnor_result),
        .q(q)
    );
endmodule

// Combinational logic module
module XNOR_Combo(
    input [7:0] a, b,
    output [7:0] result
);
    wire [7:0] xor_intermediate;
    
    // Compute XOR result
    assign xor_intermediate = a ^ b;
    
    // Compute XNOR by inverting XOR result
    assign result = ~xor_intermediate;
endmodule

// Sequential logic module
module XNOR_Seq(
    input clk,
    input [7:0] d,
    output reg [7:0] q
);
    // Register the result on clock edge
    always @(posedge clk) begin
        q <= d;
    end
endmodule