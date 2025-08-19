//SystemVerilog
// Top-level module - 3-input AND gate with improved hierarchical structure
module and_gate_3_for (
    input  wire a,  // Input A
    input  wire b,  // Input B
    input  wire c,  // Input C
    output wire y   // Output Y
);
    // Internal signals
    wire [2:0] input_bus;
    
    // Instantiate input handler module
    input_conditioning input_processor (
        .input_a(a),
        .input_b(b),
        .input_c(c),
        .input_bus(input_bus)
    );
    
    // Instantiate AND computation module with parametrized width
    and_computation_engine #(
        .INPUT_WIDTH(3)
    ) logic_core (
        .input_vector(input_bus),
        .result(y)
    );
    
endmodule

// Enhanced input conditioning module
module input_conditioning (
    input  wire input_a,
    input  wire input_b,
    input  wire input_c,
    output wire [2:0] input_bus
);
    // Pack inputs into a bus with improved signal isolation
    assign input_bus[0] = input_a;
    assign input_bus[1] = input_b;
    assign input_bus[2] = input_c;
    
endmodule

// Parameterized AND computation engine
module and_computation_engine #(
    parameter INPUT_WIDTH = 3
)(
    input  wire [INPUT_WIDTH-1:0] input_vector,
    output wire result
);
    // Internal signals
    reg  logic_result;
    
    // Optimized loop-based AND computation
    always @(*) begin
        logic_result = 1'b1;  // Initial value
        
        // Compute AND of all inputs using optimized loop
        for (integer i = 0; i < INPUT_WIDTH; i = i + 1) begin
            logic_result = logic_result & input_vector[i];
        end
    end
    
    // Drive output with computed result
    assign result = logic_result;
    
endmodule