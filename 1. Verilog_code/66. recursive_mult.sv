module recursive_mult #(parameter W=8) (
    input [W-1:0] x, y,
    output [2*W-1:0] p
);
    // This implementation uses an iterative approach
    // to calculate multiplication in a divide-and-conquer manner
    
    // For W=1, simple multiplier
    generate
        if (W == 1) begin
            assign p = x & y;
        end
        // For W=2, use 4 AND gates and adders
        else if (W == 2) begin
            wire [3:0] pp;
            assign pp[0] = x[0] & y[0];
            assign pp[1] = x[0] & y[1];
            assign pp[2] = x[1] & y[0];
            assign pp[3] = x[1] & y[1];
            
            assign p[0] = pp[0];
            assign p[1] = pp[1] ^ pp[2];
            assign p[2] = pp[3] ^ (pp[1] & pp[2]);
            assign p[3] = (pp[1] & pp[2]) & pp[3];
        end
        // For W=4 or W=8, use hierarchical approach with smaller multipliers
        else begin
            localparam H = W/2;
            
            // Split inputs into high and low halves
            wire [H-1:0] x_lo, y_lo;
            wire [H-1:0] x_hi, y_hi;
            
            assign x_lo = x[H-1:0];
            assign x_hi = x[W-1:H];
            assign y_lo = y[H-1:0];
            assign y_hi = y[W-1:H];
            
            // Calculate partial products
            wire [2*H-1:0] p_lo_lo; // Lower x * Lower y
            wire [2*H-1:0] p_hi_lo; // Higher x * Lower y
            wire [2*H-1:0] p_lo_hi; // Lower x * Higher y
            wire [2*H-1:0] p_hi_hi; // Higher x * Higher y
            
            // Instantiate smaller multipliers
            recursive_mult #(.W(H)) mult_lo_lo (
                .x(x_lo),
                .y(y_lo),
                .p(p_lo_lo)
            );
            
            recursive_mult #(.W(H)) mult_hi_lo (
                .x(x_hi),
                .y(y_lo),
                .p(p_hi_lo)
            );
            
            recursive_mult #(.W(H)) mult_lo_hi (
                .x(x_lo),
                .y(y_hi),
                .p(p_lo_hi)
            );
            
            recursive_mult #(.W(H)) mult_hi_hi (
                .x(x_hi),
                .y(y_hi),
                .p(p_hi_hi)
            );
            
            // Combine partial products
            wire [2*W-1:0] stage1, stage2;
            
            // p_lo_lo is placed at [0 +: 2*H]
            assign stage1[0 +: 2*H] = p_lo_lo;
            assign stage1[2*H +: 2*H] = p_hi_hi;
            
            // p_hi_lo and p_lo_hi are added and shifted by H
            wire [2*H:0] middle_sum; // +1 bit for carry
            assign middle_sum = p_hi_lo + p_lo_hi;
            
            // Add middle term (shifted by H)
            assign stage2 = stage1 + (middle_sum << H);
            
            // Assign to output
            assign p = stage2;
        end
    endgenerate
endmodule