//SystemVerilog
module bidir_parity_module(
    input [15:0] data,
    input even_odd_sel,  // 0-even, 1-odd
    output reg parity_out
);

// Optimize parity calculation by doing reduction in stages
// This creates a balanced tree structure for better timing
wire [7:0] stage1;
wire [3:0] stage2;
wire [1:0] stage3;
wire parity_result;

// Stage 1: Reduce 16 bits to 8 bits
generate
    for (genvar i = 0; i < 8; i++) begin : GEN_STAGE1
        assign stage1[i] = data[i*2] ^ data[i*2+1];
    end
endgenerate

// Stage 2: Reduce 8 bits to 4 bits
generate
    for (genvar i = 0; i < 4; i++) begin : GEN_STAGE2
        assign stage2[i] = stage1[i*2] ^ stage1[i*2+1];
    end
endgenerate

// Stage 3: Reduce 4 bits to 2 bits
generate
    for (genvar i = 0; i < 2; i++) begin : GEN_STAGE3
        assign stage3[i] = stage2[i*2] ^ stage2[i*2+1];
    end
endgenerate

// Final stage: Get the parity result
assign parity_result = stage3[0] ^ stage3[1];

// Apply even/odd selection
always @(*) begin
    parity_out = even_odd_sel ? ~parity_result : parity_result;
end

endmodule