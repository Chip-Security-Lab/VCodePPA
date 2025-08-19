//SystemVerilog
module BoothMultiplier #(parameter W=8) (
    input [W-1:0] multiplicand,
    input [W-1:0] multiplier,
    output reg [2*W-1:0] product
);
    reg [W:0] A;
    reg [W:0] Q;
    reg Q_1;
    reg [W:0] M;
    integer i;

    always @(*) begin
        A = 0;
        Q = multiplier;
        Q_1 = 0;
        M = multiplicand;
        
        for (i = 0; i < W; i = i + 1) begin
            case ({Q[0], Q_1})
                2'b01: A = A + M;
                2'b10: A = A - M;
                default: A = A;
            endcase
            
            {A, Q, Q_1} = {A[W], A, Q} >> 1;
        end
        
        product = {A[W-1:0], Q[W-1:0]};
    end
endmodule

module MuxDynamic #(parameter W=8, N=4) (
    input [N*W-1:0] stream,
    input [$clog2(N)-1:0] ch_sel,
    output reg [W-1:0] active_ch
);
    integer i;
    always @(*) begin
        active_ch = 0;
        for (i = 0; i < N; i = i + 1) begin
            if (ch_sel == i) 
                active_ch = stream[i*W +: W];
        end
    end
endmodule