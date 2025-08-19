module nand2_18 (
    input wire A, B,
    output reg Y
);
    reg and_out;  // Changed from wire to reg

    // Compute AND using always block
    always @(A or B) begin
        and_out = A & B;
        Y = ~and_out;  // Both assignments in the same always block
    end
endmodule