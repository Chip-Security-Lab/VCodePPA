//SystemVerilog
module recursive_mult #(parameter W=8) (
    input [W-1:0] x, y,
    output [2*W-1:0] p
);
    generate
        case(W)
            1: begin
                assign p = x & y;
            end
            
            2: begin
                wire [3:0] pp;
                wire [1:0] sum;
                
                assign pp[0] = x[0] & y[0];
                assign pp[1] = x[0] & y[1];
                assign pp[2] = x[1] & y[0];
                assign pp[3] = x[1] & y[1];
                
                assign sum = pp[1] + pp[2];
                
                assign p[0] = pp[0];
                assign p[1] = sum[0];
                assign p[2] = pp[3] ^ sum[1];
                assign p[3] = pp[3] & sum[1];
            end
            
            default: begin
                localparam H = W/2;
                
                wire [H-1:0] x_lo, y_lo;
                wire [H-1:0] x_hi, y_hi;
                
                assign {x_hi, x_lo} = x;
                assign {y_hi, y_lo} = y;
                
                wire [2*H-1:0] p_lo_lo;
                wire [2*H-1:0] p_hi_lo;
                wire [2*H-1:0] p_lo_hi;
                wire [2*H-1:0] p_hi_hi;
                
                recursive_mult #(.W(H)) mult_lo_lo (.x(x_lo), .y(y_lo), .p(p_lo_lo));
                recursive_mult #(.W(H)) mult_hi_lo (.x(x_hi), .y(y_lo), .p(p_hi_lo));
                recursive_mult #(.W(H)) mult_lo_hi (.x(x_lo), .y(y_hi), .p(p_lo_hi));
                recursive_mult #(.W(H)) mult_hi_hi (.x(x_hi), .y(y_hi), .p(p_hi_hi));
                
                wire [2*H:0] middle_sum;
                wire [2*W-1:0] result;
                wire [2*W-1:0] shifted_sum;
                
                assign middle_sum = p_hi_lo + p_lo_hi;
                
                // Barrel shifter implementation
                genvar i;
                for (i = 0; i < 2*W; i = i + 1) begin
                    assign shifted_sum[i] = (i >= H && i < 3*H) ? middle_sum[i-H] : 1'b0;
                end
                
                assign result = {p_hi_hi, p_lo_lo} + shifted_sum;
                assign p = result;
            end
        endcase
    endgenerate
endmodule