//SystemVerilog
// Top-level module: shift_right_arithmetic
// Function: Hierarchically performs signed arithmetic right shift on input data

module shift_right_arithmetic #(parameter WIDTH=8) (
    input                  clk,
    input                  en,
    input  signed [WIDTH-1:0] data_in,
    input        [2:0]     shift,
    output signed [WIDTH-1:0] data_out
);

    // Internal signals for registered inputs
    wire signed [WIDTH-1:0] data_in_reg;
    wire        [2:0]       shift_reg;

    // Internal signal for shifted output
    wire signed [WIDTH-1:0] shifted_out;

    // Instance: Registers input data and shift amount
    shift_right_arithmetic_reg #(.WIDTH(WIDTH)) u_input_reg (
        .clk        (clk),
        .en         (en),
        .data_in    (data_in),
        .shift      (shift),
        .data_in_reg(data_in_reg),
        .shift_reg  (shift_reg)
    );

    // Instance: Performs arithmetic shift operation
    shift_right_arithmetic_core #(.WIDTH(WIDTH)) u_shift_core (
        .clk        (clk),
        .en         (en),
        .data_in_reg(data_in_reg),
        .shift_reg  (shift_reg),
        .shifted_out(shifted_out)
    );

    // Output register: holds the final shifted result
    shift_right_arithmetic_outreg #(.WIDTH(WIDTH)) u_output_reg (
        .clk        (clk),
        .en         (en),
        .shifted_in (shifted_out),
        .data_out   (data_out)
    );

endmodule

//------------------------------------------------------------------------------
// Submodule: shift_right_arithmetic_reg
// Function: Registers input data and shift amount on rising edge of clk when enabled
//------------------------------------------------------------------------------
module shift_right_arithmetic_reg #(parameter WIDTH=8) (
    input                  clk,
    input                  en,
    input  signed [WIDTH-1:0] data_in,
    input        [2:0]     shift,
    output reg signed [WIDTH-1:0] data_in_reg,
    output reg        [2:0] shift_reg
);
    always @(posedge clk) begin
        if (en) begin
            data_in_reg <= data_in;
            shift_reg   <= shift;
        end
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: shift_right_arithmetic_core
// Function: Performs signed arithmetic right shift operation
//------------------------------------------------------------------------------
module shift_right_arithmetic_core #(parameter WIDTH=8) (
    input                  clk,
    input                  en,
    input  signed [WIDTH-1:0] data_in_reg,
    input        [2:0]     shift_reg,
    output reg signed [WIDTH-1:0] shifted_out
);
    always @(posedge clk) begin
        if (en) begin
            shifted_out <= data_in_reg >>> shift_reg;
        end
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: shift_right_arithmetic_outreg
// Function: Registers the shifted output result
//------------------------------------------------------------------------------
module shift_right_arithmetic_outreg #(parameter WIDTH=8) (
    input                  clk,
    input                  en,
    input  signed [WIDTH-1:0] shifted_in,
    output reg signed [WIDTH-1:0] data_out
);
    always @(posedge clk) begin
        if (en) begin
            data_out <= shifted_in;
        end
    end
endmodule