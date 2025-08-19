//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: bidirectional_piso_top.v
// Description: Bidirectional Parallel-In-Serial-Out shift register top module
///////////////////////////////////////////////////////////////////////////////

module BidirectionalPISO #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire load,
    input wire left_right,
    input wire [WIDTH-1:0] parallel_in,
    output wire serial_out
);

    // Internal connections
    wire [WIDTH-1:0] buffer_out;
    wire selected_bit;
    wire [WIDTH-1:0] processed_data;

    // Instantiate the conditional sum subtractor
    ConditionalSumSubtractor #(
        .WIDTH(WIDTH)
    ) subtractor (
        .a(parallel_in),
        .b(8'h01),         // Subtract 1 as an example operation
        .result(processed_data)
    );

    // Instantiate the shift register controller
    ShiftRegisterController #(
        .WIDTH(WIDTH)
    ) shift_reg_ctrl (
        .clk(clk),
        .load(load),
        .left_right(left_right),
        .parallel_in(processed_data),  // Use the result from subtractor
        .buffer_out(buffer_out)
    );

    // Instantiate the bit selector
    BitSelector #(
        .WIDTH(WIDTH)
    ) bit_sel (
        .left_right(left_right),
        .buffer_data(buffer_out),
        .selected_bit(selected_bit)
    );

    // Instantiate the output register
    OutputRegister out_reg (
        .clk(clk),
        .bit_in(selected_bit),
        .serial_out(serial_out)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// Conditional Sum Subtractor Module
// Implements subtraction using conditional sum algorithm
///////////////////////////////////////////////////////////////////////////////

module ConditionalSumSubtractor #(
    parameter WIDTH = 8
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] result
);
    // Internal signals
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] diff0, diff1;
    wire [WIDTH-1:0] sel;
    
    // Initial borrow
    assign borrow[0] = 1'b0;
    
    // Generate conditional differences and selectors
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_conditional_diff
            // Compute differences with and without borrow
            assign diff0[i] = a[i] ^ b[i];
            assign diff1[i] = a[i] ^ b[i] ^ 1'b1;
            
            // Compute borrow propagation
            assign sel[i] = ~a[i] & b[i] | (~a[i] | b[i]) & borrow[i];
            assign borrow[i+1] = sel[i];
            
            // Select the appropriate difference based on borrow
            assign result[i] = borrow[i] ? diff1[i] : diff0[i];
        end
    endgenerate
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Shift Register Controller Module
// Handles the shifting operations based on direction and load signal
///////////////////////////////////////////////////////////////////////////////

module ShiftRegisterController #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire load,
    input wire left_right,
    input wire [WIDTH-1:0] parallel_in,
    output reg [WIDTH-1:0] buffer_out
);

    always @(posedge clk) begin
        if (load) 
            buffer_out <= parallel_in;
        else if (left_right)
            buffer_out <= {buffer_out[WIDTH-2:0], 1'b0}; // Shift left
        else
            buffer_out <= {1'b0, buffer_out[WIDTH-1:1]}; // Shift right
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Bit Selector Module
// Selects the appropriate output bit based on shift direction
///////////////////////////////////////////////////////////////////////////////

module BitSelector #(
    parameter WIDTH = 8
) (
    input wire left_right,
    input wire [WIDTH-1:0] buffer_data,
    output wire selected_bit
);

    // Select MSB when shifting left, LSB when shifting right
    assign selected_bit = left_right ? buffer_data[WIDTH-1] : buffer_data[0];

endmodule

///////////////////////////////////////////////////////////////////////////////
// Output Register Module
// Registers the output bit to prevent glitches
///////////////////////////////////////////////////////////////////////////////

module OutputRegister (
    input wire clk,
    input wire bit_in,
    output reg serial_out
);

    always @(posedge clk) begin
        serial_out <= bit_in;
    end

endmodule