//SystemVerilog
module recursive_mult #(parameter W=8) (
    input [W-1:0] x, y,
    output [2*W-1:0] p
);
    generate
        case (W)
            1: begin
                assign p = x & y;
            end
            2: begin
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
            default: begin
                localparam H = W/2;
                
                wire [H-1:0] x_lo, y_lo;
                wire [H-1:0] x_hi, y_hi;
                
                assign x_lo = x[H-1:0];
                assign x_hi = x[W-1:H];
                assign y_lo = y[H-1:0];
                assign y_hi = y[W-1:H];
                
                wire [2*H-1:0] p_lo_lo;
                wire [2*H-1:0] p_hi_lo;
                wire [2*H-1:0] p_lo_hi;
                wire [2*H-1:0] p_hi_hi;
                
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
                
                wire [2*W-1:0] stage1;
                wire [2*H:0] middle_sum;
                wire [2*H:0] g, p;
                wire [2*H:0] c;
                
                assign stage1[0 +: 2*H] = p_lo_lo;
                assign stage1[2*H +: 2*H] = p_hi_hi;
                
                assign g = p_hi_lo & p_lo_hi;
                assign p = p_hi_lo ^ p_lo_hi;
                
                assign c[0] = 1'b0;
                assign c[1] = g[0];
                assign c[2] = g[1] | (p[1] & g[0]);
                assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
                assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
                
                assign middle_sum = p ^ {c[2*H-1:0], 1'b0};
                
                assign p = stage1 + (middle_sum << H);
            end
        endcase
    endgenerate
endmodule