//SystemVerilog
module open_ended_range_detector(
    input wire [11:0] data,
    input wire [11:0] bound_value,
    input wire direction, // 0=lower_bound_only, 1=upper_bound_only
    output wire in_valid_zone
);
    // Internal signals
    wire lower_bound_check;
    wire upper_bound_check;
    wire selected_result;
    
    // Instantiate the comparator module for lower bound checking
    comparator_module #(
        .WIDTH(12),
        .OPERATION("GE")  // Greater than or Equal
    ) lower_bound_comparator (
        .a(data),
        .b(bound_value),
        .result(lower_bound_check)
    );
    
    // Instantiate the comparator module for upper bound checking
    comparator_module #(
        .WIDTH(12),
        .OPERATION("LE")  // Less than or Equal
    ) upper_bound_comparator (
        .a(data),
        .b(bound_value),
        .result(upper_bound_check)
    );
    
    // Instantiate selector module to choose the appropriate result
    result_selector selector (
        .lower_result(lower_bound_check),
        .upper_result(upper_bound_check),
        .select_control(direction),
        .final_result(in_valid_zone)
    );
    
endmodule

// Parameterized comparator module for flexible comparison operations
module comparator_module #(
    parameter WIDTH = 12,
    parameter OPERATION = "GE"  // "GE" for >=, "LE" for <=
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output reg result
);
    // Perform the appropriate comparison based on the operation parameter
    always @(*) begin
        case (OPERATION)
            "GE": result = (a >= b);
            "LE": result = (a <= b);
            default: result = 1'b0;
        endcase
    end
endmodule

// Selector module to choose between comparison results
module result_selector(
    input wire lower_result,
    input wire upper_result,
    input wire select_control,
    output wire final_result
);
    // Select between lower_result and upper_result based on select_control
    // select_control: 0=lower_bound_only, 1=upper_bound_only
    assign final_result = select_control ? upper_result : lower_result;
endmodule