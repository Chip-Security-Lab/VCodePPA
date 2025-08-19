//SystemVerilog
//IEEE 1364-2005 Verilog
// Top-level module: Parameterized AND gate
module and_gate_parameterized #(
    parameter INPUT_WIDTH = 2,    // Number of inputs
    parameter OUTPUT_REGISTERED = 0,  // 0: combinational, 1: registered output
    parameter GATE_STRENGTH = "MEDIUM" // "LOW", "MEDIUM", "HIGH" drive strength
)(
    input wire clk,                      // Clock (used when OUTPUT_REGISTERED=1)
    input wire [INPUT_WIDTH-1:0] inputs, // Input bus
    output wire out                      // Output
);

    // Internal signal
    wire combinational_out;
    
    // Instantiate the optimized AND function module
    and_function #(
        .WIDTH(INPUT_WIDTH),
        .STRENGTH(GATE_STRENGTH)
    ) and_func_inst (
        .in(inputs),
        .out(combinational_out)
    );
    
    // Optimized output stage
    output_stage #(
        .REGISTERED(OUTPUT_REGISTERED)
    ) out_stage_inst (
        .clk(clk),
        .in(combinational_out),
        .out(out)
    );
    
endmodule

// Submodule: Optimized AND function implementation
module and_function #(
    parameter WIDTH = 2,
    parameter STRENGTH = "MEDIUM"
)(
    input wire [WIDTH-1:0] in,
    output wire out
);
    // Optimized implementation with segmented reduction for large widths
    generate
        if (WIDTH <= 4) begin : small_width
            // Direct reduction for small widths
            if (STRENGTH == "LOW") begin : low_strength
                assign (weak0, weak1) out = &in;
            end
            else if (STRENGTH == "HIGH") begin : high_strength
                assign (strong0, strong1) out = &in;
            end
            else begin : medium_strength
                assign out = &in;
            end
        end
        else begin : large_width
            // For larger widths, use a balanced tree approach
            wire [((WIDTH+1)/2)-1:0] intermediate;
            
            genvar i;
            for (i = 0; i < WIDTH/2; i = i + 1) begin : and_tree
                assign intermediate[i] = in[i*2] & in[i*2+1];
            end
            
            // Handle odd number of inputs
            if (WIDTH % 2 == 1) begin : odd_input
                assign intermediate[(WIDTH/2)] = in[WIDTH-1];
            end
            
            // Final output with appropriate strength
            if (STRENGTH == "LOW") begin : low_strength
                assign (weak0, weak1) out = &intermediate;
            end
            else if (STRENGTH == "HIGH") begin : high_strength
                assign (strong0, strong1) out = &intermediate;
            end
            else begin : medium_strength
                assign out = &intermediate;
            end
        end
    endgenerate
    
endmodule

// Submodule: Optimized output stage
module output_stage #(
    parameter REGISTERED = 0
)(
    input wire clk,
    input wire in,
    output wire out
);
    generate
        if (REGISTERED) begin : registered_output
            // Use a more explicit register implementation
            reg reg_out = 1'b0; // Initialize to avoid X propagation
            
            always @(posedge clk)
                reg_out <= in;
                
            assign out = reg_out;
        end
        else begin : combinational_output
            // Direct pass-through for combinational mode
            assign out = in;
        end
    endgenerate
    
endmodule