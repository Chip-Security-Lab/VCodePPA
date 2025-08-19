//SystemVerilog
// Top-level module: 8-bit AND gate with reset
module and_gate_8bit_reset (
    input wire [7:0] a,    // 8-bit input A
    input wire [7:0] b,    // 8-bit input B
    input wire rst,        // Reset signal
    output wire [7:0] y    // 8-bit output Y
);
    wire [7:0] and_result;
    
    // Instantiate the basic AND operation module
    and_operation_unit and_unit (
        .a_in(a),
        .b_in(b),
        .result_out(and_result)
    );
    
    // Instantiate the reset control module
    reset_control_unit reset_unit (
        .data_in(and_result),
        .rst_in(rst),
        .data_out(y)
    );
endmodule

// Submodule for basic AND operation
module and_operation_unit (
    input wire [7:0] a_in,      // 8-bit input A
    input wire [7:0] b_in,      // 8-bit input B
    output wire [7:0] result_out // 8-bit AND result
);
    assign result_out = a_in & b_in;
endmodule

// Submodule for reset control logic
module reset_control_unit (
    input wire [7:0] data_in,   // Input data
    input wire rst_in,          // Reset signal
    output reg [7:0] data_out   // Output data with reset applied
);
    always @(*) begin
        if (rst_in)
            data_out = 8'b00000000;
        else
            data_out = data_in;
    end
endmodule