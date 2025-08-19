//SystemVerilog
module MajorityVote #(parameter N=5, M=3) (
    input [N-1:0] inputs,
    output reg vote_out
);
    reg [7:0] count;
    wire [7:0] adder_result;
    integer i;
    
    // Han-Carlson adder signals
    wire [7:0] p, g;
    wire [7:0] pp, pg;
    wire [7:0] c;
    
    always @(*) begin
        count = 0;
        for(i=0; i<N; i=i+1)
            if(inputs[i]) 
                count = adder_result;
        vote_out = (count >= M);
    end
    
    // Han-Carlson adder implementation (8-bit)
    // Pre-processing: generate p (propagate) and g (generate) signals
    assign p[0] = count[0] ^ 1'b1;
    assign g[0] = count[0] & 1'b1;
    assign p[7:1] = count[7:1] ^ {7{1'b0}};
    assign g[7:1] = count[7:1] & {7{1'b0}};
    
    // First stage: even bits
    assign pp[0] = p[0];
    assign pg[0] = g[0];
    assign pp[2] = p[2] & p[1];
    assign pg[2] = g[2] | (p[2] & g[1]);
    assign pp[4] = p[4] & p[3];
    assign pg[4] = g[4] | (p[4] & g[3]);
    assign pp[6] = p[6] & p[5];
    assign pg[6] = g[6] | (p[6] & g[5]);
    
    // Second stage: all bits
    assign c[0] = g[0];
    assign c[1] = g[1] | (p[1] & c[0]);
    assign c[2] = pg[2] | (pp[2] & c[0]);
    assign c[3] = g[3] | (p[3] & c[2]);
    assign c[4] = pg[4] | (pp[4] & c[2]);
    assign c[5] = g[5] | (p[5] & c[4]);
    assign c[6] = pg[6] | (pp[6] & c[4]);
    assign c[7] = g[7] | (p[7] & c[6]);
    
    // Post-processing: compute sum
    assign adder_result[0] = p[0] ^ 1'b0;
    assign adder_result[7:1] = p[7:1] ^ c[6:0];
    
endmodule