// Inverter module
module Inverter(
    input [7:0] input_data,
    output [7:0] inverted_data
);
    assign inverted_data = ~input_data;
endmodule

// Selector module
module Selector(
    input [7:0] original_data,
    input [7:0] inverted_data,
    input select_signal,
    output [7:0] selected_data
);
    assign selected_data = select_signal ? inverted_data : original_data;
endmodule

// Adder module
module Adder(
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum,
    output carry
);
    assign {carry, sum} = a + b;
endmodule

// Top-level module
module Sub1(
    input [7:0] a,
    input [7:0] b,
    output [7:0] result
);
    wire [7:0] b_inv;
    wire [7:0] b_sel;
    wire [7:0] sum;
    wire carry;
    
    // Instantiate inverter
    Inverter inverter_inst(
        .input_data(b),
        .inverted_data(b_inv)
    );
    
    // Instantiate selector
    Selector selector_inst(
        .original_data(b),
        .inverted_data(b_inv),
        .select_signal(carry),
        .selected_data(b_sel)
    );
    
    // Instantiate adder
    Adder adder_inst(
        .a(a),
        .b(b_sel),
        .sum(sum),
        .carry(carry)
    );
    
    // Final result
    assign result = sum;
endmodule