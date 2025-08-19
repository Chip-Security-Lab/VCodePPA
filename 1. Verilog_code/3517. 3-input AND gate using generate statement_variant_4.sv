//SystemVerilog
///////////////////////////////////////////////////////////
// Top level module for 3-input AND gate
///////////////////////////////////////////////////////////
module and_gate_3_for (
    input  wire a,  // Input A
    input  wire b,  // Input B
    input  wire c,  // Input C
    output wire y   // Output Y
);
    // Internal signals
    wire [2:0] inputs_packed;
    wire       and_result;
    
    // Input packing submodule
    input_packer input_pack_inst (
        .a(a),
        .b(b),
        .c(c),
        .packed_inputs(inputs_packed)
    );
    
    // AND operation submodule
    and_operator and_op_inst (
        .inputs(inputs_packed),
        .result(and_result)
    );
    
    // Output assignment
    assign y = and_result;
    
endmodule

///////////////////////////////////////////////////////////
// Submodule to pack individual inputs into an array
///////////////////////////////////////////////////////////
module input_packer (
    input  wire a,
    input  wire b,
    input  wire c,
    output wire [2:0] packed_inputs
);
    // Pack individual inputs into a bus
    assign packed_inputs = {a, b, c};
    
endmodule

///////////////////////////////////////////////////////////
// Submodule to perform AND operation with unrolled loop
///////////////////////////////////////////////////////////
module and_operator (
    input  wire [2:0] inputs,
    output reg        result
);
    always @(*) begin
        // Unrolled loop for better performance
        result = inputs[0] & inputs[1] & inputs[2];
    end
    
endmodule