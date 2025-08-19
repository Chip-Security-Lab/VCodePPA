//SystemVerilog
//===========================================================
// Module: Gated_AND_Top
// Description: Top-level module for gated AND operation
// Standard: IEEE 1364-2005
//===========================================================
module Gated_AND_Top (
    input        enable,
    input  [3:0] vec_a, vec_b,
    output [3:0] res
);
    wire        gate_control;
    wire  [3:0] and_result;
    
    // Gate controller instance
    Gate_Controller u_controller (
        .enable       (enable),
        .gate_control (gate_control)
    );
    
    // Vector AND operation instance
    Vector_AND u_vector_and (
        .vec_a      (vec_a),
        .vec_b      (vec_b),
        .and_result (and_result)
    );
    
    // Output selector instance
    Output_Selector u_selector (
        .gate_control (gate_control),
        .data_in      (and_result),
        .data_out     (res)
    );
    
endmodule

//===========================================================
// Module: Gate_Controller
// Description: Controls the gating signal
//===========================================================
module Gate_Controller (
    input  enable,
    output gate_control
);
    // Direct passthrough for this simple case
    assign gate_control = enable;
    
endmodule

//===========================================================
// Module: Vector_AND
// Description: Performs bitwise AND operation on input vectors
//===========================================================
module Vector_AND (
    input  [3:0] vec_a, vec_b,
    output [3:0] and_result
);
    // Compute bitwise AND
    assign and_result = vec_a & vec_b;
    
endmodule

//===========================================================
// Module: Output_Selector
// Description: Selects output based on gate control
//===========================================================
module Output_Selector (
    input        gate_control,
    input  [3:0] data_in,
    output reg [3:0] data_out
);
    // Select output based on gate control using if-else structure
    always @(*) begin
        if (gate_control) begin
            data_out = data_in;
        end
        else begin
            data_out = 4'b0000;
        end
    end
    
endmodule