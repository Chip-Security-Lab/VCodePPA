//SystemVerilog
module booth_multiplier_8bit (
    input wire [7:0] multiplicand,
    input wire [7:0] multiplier,
    output reg [15:0] product
);

    reg [7:0] A;           // Accumulator
    reg [7:0] Q;           // Multiplier
    reg Q_1;               // Q(-1) bit
    reg [7:0] M;           // Multiplicand
    integer i;

    always @* begin
        A = 8'b0;
        Q = multiplier;
        Q_1 = 1'b0;
        M = multiplicand;
        
        for (i = 0; i < 8; i = i + 1) begin
            case ({Q[0], Q_1})
                2'b01: A = A + M;
                2'b10: A = A - M;
                default: A = A;
            endcase
            
            {A, Q, Q_1} = {A[7], A, Q};
        end
        
        product = {A, Q};
    end
endmodule

module gated_sr_latch (
    input wire s,
    input wire r,
    input wire gate,
    output reg q,
    output wire q_n
);

    wire set_cond = s & ~r;
    wire reset_cond = ~s & r;
    
    assign q_n = ~q;
    
    always @* begin
        if (gate) begin
            case ({set_cond, reset_cond})
                2'b10: q = 1'b1;
                2'b01: q = 1'b0;
                default: q = q;
            endcase
        end
    end
endmodule