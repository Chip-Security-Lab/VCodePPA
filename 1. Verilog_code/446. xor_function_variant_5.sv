//SystemVerilog
module xor_function (
    input  wire clk,     // Clock input
    input  wire rst_n,   // Reset signal
    input  wire a,
    input  wire b,
    output wire y
);
    // Combinational result without register
    wire xor_result;
    
    // Output register
    reg y_result;
    
    // Internal function definition - compute XOR operation
    function automatic logic compute_xor;
        input logic operand1, operand2;
        begin
            compute_xor = operand1 ^ operand2;
        end
    endfunction
    
    // Direct combinational XOR calculation without input registers
    assign xor_result = compute_xor(a, b);
    
    // Single pipeline stage - directly register the output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_result <= 1'b0;
        end else begin
            y_result <= xor_result;
        end
    end
    
    // Output assignment
    assign y = y_result;
    
endmodule