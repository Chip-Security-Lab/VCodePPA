module xor2_6 (
    input wire A, B,
    output reg Y
);
    always @(A or B) begin
        case ({A, B})
            2'b00: Y = 0;
            2'b01: Y = 1;
            2'b10: Y = 1;
            2'b11: Y = 0;
            default: Y = 0;
        endcase
    end
endmodule
