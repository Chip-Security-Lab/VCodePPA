//SystemVerilog
module recursive_mult #(parameter W=8) (
    input [W-1:0] x, y,
    output [2*W-1:0] p
);
    generate
        if (W == 1) begin
            assign p = x & y;
        end
        else if (W == 2) begin
            wire [1:0] pp0, pp1;
            assign pp0 = {x[1] & y[0], x[0] & y[0]};
            assign pp1 = {x[1] & y[1], x[0] & y[1]};
            
            wire [1:0] sum;
            assign sum = pp0 + pp1;
            assign p = {sum[1], sum[0]};
        end
        else begin
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
            
            wire [2*H-1:0] middle_sum;
            assign middle_sum = p_hi_lo + p_lo_hi;
            
            assign p = {p_hi_hi, p_lo_lo} + (middle_sum << H);
        end
    endgenerate
endmodule