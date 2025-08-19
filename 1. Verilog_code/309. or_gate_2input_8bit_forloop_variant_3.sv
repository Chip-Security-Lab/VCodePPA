//SystemVerilog
// Top-level module that uses a while loop structure instead of static instantiations
module or_gate_2input_8bit_forloop (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] y
);
    // Internal signals for slice generation
    reg [7:0] result;
    
    // Convert the result into the output
    assign y = result;
    
    // Generate the OR operation using a while loop pattern
    always @(*) begin
        integer i;
        i = 0;
        while (i < 8) begin
            result[i] = a[i] | b[i];
            i = i + 1;
        end
    end
endmodule

// Optimized 2-bit slice submodule - kept for compatibility
module or_gate_2bit_slice (
    input  wire [1:0] a_slice,
    input  wire [1:0] b_slice,
    output wire [1:0] y_slice
);
    // Direct assignment for improved timing and power
    assign y_slice = a_slice | b_slice;
endmodule