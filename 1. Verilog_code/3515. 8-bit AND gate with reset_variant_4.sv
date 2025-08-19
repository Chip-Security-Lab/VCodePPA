//SystemVerilog IEEE 1364-2005
// Top module: 8-bit AND gate with reset
module and_gate_8bit_reset (
    input wire [7:0] a,    // 8-bit input A
    input wire [7:0] b,    // 8-bit input B
    input wire rst,        // Reset signal
    output wire [7:0] y    // 8-bit output Y (changed back to wire type)
);
    // Internal wires for connecting submodules
    wire [7:0] and_result;
    
    // Instantiate logical AND operation submodule
    logic_and_unit and_unit (
        .a_in(a),
        .b_in(b),
        .y_out(and_result)
    );
    
    // Instantiate reset handling submodule
    reset_handler reset_unit (
        .data_in(and_result),
        .rst(rst),
        .data_out(y)
    );

endmodule

// Submodule for logical AND operation
module logic_and_unit (
    input wire [7:0] a_in,
    input wire [7:0] b_in,
    output wire [7:0] y_out
);
    // Pure combinational logic for AND operation
    assign y_out = a_in & b_in;
endmodule

// Submodule for handling reset functionality
module reset_handler (
    input wire [7:0] data_in,
    input wire rst,
    output reg [7:0] data_out
);
    // Reset handling logic
    always @(*) begin
        if (rst) begin
            data_out = 8'b00000000;
        end else begin
            data_out = data_in;
        end
    end
endmodule