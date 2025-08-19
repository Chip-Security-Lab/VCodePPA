//SystemVerilog
module booth_mult (
    input [7:0] X, Y,
    output [15:0] P
);
    reg [15:0] A;
    reg [8:0] Q;
    reg [15:0] A_next;
    reg [8:0] Q_next;
    
    always @(*) begin
        // Initialize A and Q
        A_next = 16'b0;
        Q_next = {Y, 1'b0};
        
        // Booth iteration logic
        case(Q[1:0])
            2'b01: A_next = A + {X, 8'b0};
            2'b10: A_next = A - {X, 8'b0};
            default: A_next = A;
        endcase
        
        // Shift operation
        {A_next, Q_next} = {A_next[15], A_next, Q[8:1]};
        
        // Register update
        A = A_next;
        Q = Q_next;
    end
    
    assign P = A;
endmodule