module booth_mult (
    input [7:0] X, Y,
    output [15:0] P
);
    reg [15:0] A;
    reg [8:0] Q;
    integer i;
    
    always @(*) begin
        A = 16'b0;
        Q = {Y, 1'b0};
        for(i=0; i<8; i=i+1) begin
            case(Q[1:0])
                2'b01: A = A + {X, 8'b0};
                2'b10: A = A - {X, 8'b0};
                default: ;
            endcase
            {A, Q} = {A[15], A, Q[8:1]};
        end
    end
    assign P = A;
endmodule
