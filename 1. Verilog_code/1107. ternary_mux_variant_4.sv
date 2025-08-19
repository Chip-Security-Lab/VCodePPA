//SystemVerilog

// Parameterizable N-way multiplexer submodule
module generic_mux #(
    parameter WIDTH = 8,
    parameter NUM_INPUTS = 4
)(
    input  wire [$clog2(NUM_INPUTS)-1:0] select,
    input  wire [WIDTH-1:0] data_in [NUM_INPUTS-1:0],
    output wire [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] mux_result;
    integer i;

    always @(*) begin
        mux_result = {WIDTH{1'b0}};
        for (i = 0; i < NUM_INPUTS; i = i + 1) begin
            if (select == i[$clog2(NUM_INPUTS)-1:0])
                mux_result = data_in[i];
        end
    end

    assign data_out = mux_result;
endmodule

// Top-level module using the generic multiplexer
module ternary_mux (
    input  wire [1:0] selector,                       // Selection control
    input  wire [7:0] input_a, input_b, input_c, input_d, // Inputs
    output wire [7:0] mux_out                         // Output result
);
    wire [7:0] mux_inputs [3:0];

    assign mux_inputs[0] = input_a;
    assign mux_inputs[1] = input_b;
    assign mux_inputs[2] = input_c;
    assign mux_inputs[3] = input_d;

    generic_mux #(
        .WIDTH(8),
        .NUM_INPUTS(4)
    ) u_generic_mux (
        .select(selector),
        .data_in(mux_inputs),
        .data_out(mux_out)
    );
endmodule