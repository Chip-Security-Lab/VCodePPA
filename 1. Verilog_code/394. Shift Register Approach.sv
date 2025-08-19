module nand2_14 (
    input wire A, B,
    input wire clk,  // Added clock input
    output reg Y
);
    reg shift_A, shift_B;

    // Use proper synchronous design with clock
    always @(posedge clk) begin
        shift_A <= A;
        shift_B <= B;
        Y <= ~(shift_A & shift_B); // Perform NAND on shifted values
    end
endmodule