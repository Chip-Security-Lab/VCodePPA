//SystemVerilog
// Top-level module: Hierarchical shift right arithmetic (optimized with forward register retiming)
module shift_right_arithmetic #(parameter WIDTH=8) (
    input  wire                  clk,
    input  wire                  en,
    input  wire signed [WIDTH-1:0] data_in,
    input  wire [2:0]            shift,
    output reg  signed [WIDTH-1:0] data_out
);

    wire signed [WIDTH-1:0] shifted_result;

    // Shift unit: Performs arithmetic right shift directly from inputs
    shift_right_arithmetic_unit #(.WIDTH(WIDTH)) u_shift_unit (
        .data_in  (data_in),
        .shift    (shift),
        .result   (shifted_result)
    );

    // Register unit: Registers the shifted result on clk if enabled
    shift_right_arithmetic_reg #(.WIDTH(WIDTH)) u_reg (
        .clk      (clk),
        .en       (en),
        .data_in  (shifted_result),
        .data_out (data_out)
    );

endmodule

// ---------------------------------------------------------------------
// Shift Unit: Performs arithmetic right shift operation
// Inputs:
//   - data_in: signed input data
//   - shift: shift amount
// Outputs:
//   - result: shifted and sign-extended output
// ---------------------------------------------------------------------
module shift_right_arithmetic_unit #(parameter WIDTH=8) (
    input  wire signed [WIDTH-1:0] data_in,
    input  wire [2:0]              shift,
    output wire signed [WIDTH-1:0] result
);
    assign result = data_in >>> shift;
endmodule

// ---------------------------------------------------------------------
// Register Unit: Registers data on rising edge of clk when enabled
// Inputs:
//   - clk: clock signal
//   - en: enable signal
//   - data_in: input data to register
// Outputs:
//   - data_out: registered output data
// ---------------------------------------------------------------------
module shift_right_arithmetic_reg #(parameter WIDTH=8) (
    input  wire                  clk,
    input  wire                  en,
    input  wire signed [WIDTH-1:0] data_in,
    output reg  signed [WIDTH-1:0] data_out
);
    always @(posedge clk) begin
        if(en) begin
            data_out <= data_in;
        end
    end
endmodule