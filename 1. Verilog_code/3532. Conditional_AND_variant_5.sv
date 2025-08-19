//SystemVerilog
module Conditional_AND_Top (
    input sel,
    input [7:0] op_a, op_b,
    output [7:0] res
);
    // Internal signals
    wire [7:0] and_result;
    wire [7:0] default_value;
    
    // Instantiate submodules
    Bitwise_AND bitwise_and_inst (
        .in_a(op_a),
        .in_b(op_b),
        .out_result(and_result)
    );
    
    Default_Value default_value_inst (
        .out_value(default_value)
    );
    
    Result_Selector result_selector_inst (
        .select(sel),
        .and_result(and_result),
        .default_value(default_value),
        .final_result(res)
    );
    
endmodule

// Submodule for bitwise AND operation
module Bitwise_AND (
    input [7:0] in_a, in_b,
    output [7:0] out_result
);
    assign out_result = in_a & in_b;
endmodule

// Submodule for providing default value
module Default_Value (
    output [7:0] out_value
);
    assign out_value = 8'hFF;
endmodule

// Submodule for selecting final result based on control signal
module Result_Selector (
    input select,
    input [7:0] and_result, default_value,
    output reg [7:0] final_result
);
    always @(*) begin
        final_result = select ? and_result : default_value;
    end
endmodule