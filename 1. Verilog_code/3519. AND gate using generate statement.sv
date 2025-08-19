// AND gate using generate statement
module and_gate_generate (
    input wire a,  // Input A
    input wire b,  // Input B
    output wire y  // Output Y
);
    genvar i;
    generate
        for (i = 0; i < 1; i = i + 1) begin : and_gen
            assign y = a & b;  // AND operation using generate statement
        end
    endgenerate
endmodule
