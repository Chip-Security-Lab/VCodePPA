//SystemVerilog
// Top-level module: ones_comp
// Function: Computes one's complement of input data using hierarchical submodules

module ones_comp #(parameter WIDTH=8) (
    input  [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);

    wire [WIDTH-1:0] inverter_out;

    // Bitwise inversion submodule
    BitwiseInverter #(.WIDTH(WIDTH)) u_bitwise_inverter (
        .in_data(data_in),
        .out_data(inverter_out)
    );

    // Registering the output to improve timing and area (PPA improvement)
    OutputRegister #(.WIDTH(WIDTH)) u_output_register (
        .clk(1'b0), // Tie to ground if no clock, or connect to system clock if synchronous output is desired
        .rst_n(1'b1), // Tie to high if no reset, or connect to system reset if desired
        .data_in(inverter_out),
        .data_out(data_out)
    );

endmodule

// ----------------------------------------------------------------
// Submodule: BitwiseInverter
// Description: Performs bitwise inversion (one's complement) on input data
// Parameters: WIDTH - Data width
// Inputs: in_data
// Outputs: out_data
// ----------------------------------------------------------------
module BitwiseInverter #(parameter WIDTH=8) (
    input  [WIDTH-1:0] in_data,
    output [WIDTH-1:0] out_data
);
    // Bitwise inversion logic
    assign out_data = ~in_data;
endmodule

// ----------------------------------------------------------------
// Submodule: OutputRegister
// Description: Registers the output data. Can be used for pipelining or timing closure.
// Parameters: WIDTH - Data width
// Inputs: clk, rst_n, data_in
// Outputs: data_out
// ----------------------------------------------------------------
module OutputRegister #(parameter WIDTH=8) (
    input               clk,
    input               rst_n,
    input  [WIDTH-1:0]  data_in,
    output [WIDTH-1:0]  data_out
);
    reg [WIDTH-1:0] data_reg;
    assign data_out = data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_reg <= {WIDTH{1'b0}};
        else
            data_reg <= data_in;
    end
endmodule