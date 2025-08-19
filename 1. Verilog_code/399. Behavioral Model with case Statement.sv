module nand2_19 (
    input wire A, B,
    output reg Y
);

    always @(A or B) begin
        case ({A, B})
            2'b00: Y = 1; // NAND(0,0) = 1
            2'b01: Y = 1; // NAND(0,1) = 1
            2'b10: Y = 1; // NAND(1,0) = 1
            2'b11: Y = 0; // NAND(1,1) = 0
            default: Y = 1;
        endcase
    end
endmodule
