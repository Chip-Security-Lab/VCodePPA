//SystemVerilog
// Top-level bidirectional cyclic shifter module
module shift_bidir_cycl #(parameter WIDTH = 8) (
    input wire clk,
    input wire dir,
    input wire en,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);

    wire [WIDTH-1:0] left_shifted;
    wire [WIDTH-1:0] right_shifted;

    // Left cyclic shift submodule instance
    shift_left_cyclic #(.WIDTH(WIDTH)) u_shift_left_cyclic (
        .in_data(data_in),
        .out_data(left_shifted)
    );

    // Right cyclic shift submodule instance
    shift_right_cyclic #(.WIDTH(WIDTH)) u_shift_right_cyclic (
        .in_data(data_in),
        .out_data(right_shifted)
    );

    // Output register logic
    always @(posedge clk) begin
        if (en) begin
            data_out <= dir ? right_shifted : left_shifted;
        end
    end

endmodule

// -------------------------------------------------------------------
// Submodule: shift_left_cyclic
// Function: Performs left cyclic shift on input data
// -------------------------------------------------------------------
module shift_left_cyclic #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] in_data,
    output wire [WIDTH-1:0] out_data
);
    assign out_data = {in_data[WIDTH-2:0], in_data[WIDTH-1]};
endmodule

// -------------------------------------------------------------------
// Submodule: shift_right_cyclic
// Function: Performs right cyclic shift on input data
// -------------------------------------------------------------------
module shift_right_cyclic #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] in_data,
    output wire [WIDTH-1:0] out_data
);
    assign out_data = {in_data[0], in_data[WIDTH-1:1]};
endmodule