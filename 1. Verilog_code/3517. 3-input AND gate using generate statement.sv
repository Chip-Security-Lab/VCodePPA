// 3-input AND gate using for loop
module and_gate_3_for (
    input wire a,  // Input A
    input wire b,  // Input B
    input wire c,  // Input C
    output reg y   // Output Y
);
    integer i;
    reg [2:0] inputs;  // Array to hold inputs
    always @(*) begin
        inputs = {a, b, c};  // Assign inputs
        y = 1'b1;  // Initial value
        for (i = 0; i < 3; i = i + 1) begin
            y = y & inputs[i];  // AND operation for each input
        end
    end
endmodule
