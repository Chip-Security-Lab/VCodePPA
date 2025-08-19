//SystemVerilog
module CarryLookaheadSubtractor #(parameter W=8) (
    input [W-1:0] a,
    input [W-1:0] b,
    output [W-1:0] diff,
    output borrow
);
    // Generate and propagate signals
    wire [W-1:0] g, p;
    wire [W:0] c;
    
    // Initialize carry-in (borrow-in) to 1 for subtraction
    assign c[0] = 1'b1;
    
    // Generate and propagate logic
    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin : gen_prop
            assign g[i] = a[i] & ~b[i];
            assign p[i] = a[i] ^ ~b[i];
        end
    endgenerate
    
    // Carry lookahead logic
    wire [W-1:0] c_lookahead;
    assign c_lookahead[0] = g[0] | (p[0] & c[0]);
    
    genvar j;
    generate
        for (j = 1; j < W; j = j + 1) begin : gen_carry
            assign c_lookahead[j] = g[j] | (p[j] & c_lookahead[j-1]);
        end
    endgenerate
    
    // Assign carries
    assign c[W:1] = c_lookahead;
    
    // Calculate difference
    genvar k;
    generate
        for (k = 0; k < W; k = k + 1) begin : gen_diff
            assign diff[k] = p[k] ^ c[k];
        end
    endgenerate
    
    // Final borrow
    assign borrow = c[W];
endmodule

module MuxHierarchy #(parameter W=4) (
    input [7:0][W-1:0] group,
    input [2:0] addr,
    output [W-1:0] data
);
    wire [1:0][W-1:0] stage1 = addr[2] ? group[7:4] : group[3:0];
    assign data = stage1[addr[1:0]];
endmodule

module TopModule #(parameter W=4) (
    input [7:0][W-1:0] group,
    input [2:0] addr,
    input [W-1:0] a,
    input [W-1:0] b,
    output [W-1:0] data,
    output [W-1:0] diff,
    output borrow
);
    // Instantiate the multiplexer hierarchy
    MuxHierarchy #(W) mux_inst (
        .group(group),
        .addr(addr),
        .data(data)
    );
    
    // Instantiate the carry-lookahead subtractor
    CarryLookaheadSubtractor #(W) subtractor_inst (
        .a(a),
        .b(b),
        .diff(diff),
        .borrow(borrow)
    );
endmodule