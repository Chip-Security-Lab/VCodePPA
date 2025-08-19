//SystemVerilog
module int_ctrl_dist_arb #(
    parameter N = 4
)(
    input [N-1:0] req,
    output [N-1:0] grant
);
    wire [N-1:0] borrow;
    wire [N-1:0] diff;
    
    // Implement borrow subtraction algorithm with explicit mux structure
    // borrow[0] initialized to 0 (no initial borrow)
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < N-1; i = i + 1) begin : gen_borrow
            // Calculate borrow for next bit using explicit multiplexer structure
            assign borrow[i+1] = ({req[i], borrow[i]} == 2'b01) ? 1'b1 : 1'b0;
            
            // Calculate difference using explicit XOR
            assign diff[i] = req[i] ^ borrow[i];
        end
    endgenerate
    
    // Handle the most significant bit
    assign diff[N-1] = req[N-1] ^ borrow[N-1];
    
    // Final grant calculation
    assign grant = req & (~diff);
endmodule