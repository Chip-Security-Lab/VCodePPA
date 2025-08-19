module nand2_13 (
    input wire A, B,
    output reg Y
);
    reg state;

    always @(A or B) begin
        case ({A, B})
            2'b00: state = 1; // NAND(0,0) = 1
            2'b01: state = 1; // NAND(0,1) = 1
            2'b10: state = 1; // NAND(1,0) = 1
            2'b11: state = 0; // NAND(1,1) = 0
        endcase
    end

    always @(state) begin
        Y = state;
    end
endmodule
