//SystemVerilog
module IVMU_PrefetchBuf #(parameter DEPTH=2) (
    input clk,
    input [31:0] vec_in,
    output reg [31:0] vec_out
);

    reg [31:0] buffer [0:DEPTH-1];
    integer i;

    // Add a calculation involving 32-bit two's complement subtraction
    // This uses standard Verilog subtraction, which is two's complement.
    wire [31:0] input_output_difference;
    assign input_output_difference = vec_in - vec_out;

    // Original buffer logic - first element
    always @(posedge clk) begin
        buffer[0] <= vec_in;
    end

    // Shift logic - transformed from for loop to while loop
    always @(posedge clk) begin
        // Initialize loop variable before the while loop
        i = DEPTH-1;
        // Equivalent while loop for the original for loop
        while (i > 0) begin
            // Loop body: Shift data
            buffer[i] <= buffer[i-1];
            // Iteration step: Decrement loop variable
            i = i - 1;
        end
    end

    // Output logic
    always @(posedge clk) begin
        vec_out <= buffer[DEPTH-1];
    end

endmodule