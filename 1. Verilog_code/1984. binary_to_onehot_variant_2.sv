//SystemVerilog
// Top-level module: Hierarchical binary to one-hot encoder with pipelined stages

module binary_to_onehot #(parameter BINARY_WIDTH=3)(
    input  wire                          clk,
    input  wire [BINARY_WIDTH-1:0]       binary_in,
    output wire [2**BINARY_WIDTH-1:0]    onehot_out
);

    // Stage 1: Input Register
    wire [BINARY_WIDTH-1:0] binary_stage1;
    binary_input_register #(.DATA_WIDTH(BINARY_WIDTH)) u_input_reg (
        .clk(clk),
        .din(binary_in),
        .dout(binary_stage1)
    );

    // Stage 2: Shift Amount Register
    wire [BINARY_WIDTH-1:0] shift_amount_stage2;
    binary_stage_register #(.DATA_WIDTH(BINARY_WIDTH)) u_shift_reg (
        .clk(clk),
        .din(binary_stage1),
        .dout(shift_amount_stage2)
    );

    // Stage 3: One-hot Generation
    wire [2**BINARY_WIDTH-1:0] onehot_stage3;
    onehot_generator #(.BINARY_WIDTH(BINARY_WIDTH)) u_onehot_gen (
        .clk(clk),
        .shift_amount(shift_amount_stage2),
        .onehot_out(onehot_stage3)
    );

    // Stage 4: Output Register
    onehot_output_register #(.ONEHOT_WIDTH(2**BINARY_WIDTH)) u_output_reg (
        .clk(clk),
        .din(onehot_stage3),
        .dout(onehot_out)
    );

endmodule

// --------------------------------------------------------------
// Submodule: binary_input_register
// Registers the binary input to break long combinational paths
module binary_input_register #(parameter DATA_WIDTH=3)(
    input  wire                  clk,
    input  wire [DATA_WIDTH-1:0] din,
    output reg  [DATA_WIDTH-1:0] dout
);
    always @(posedge clk) begin
        dout <= din;
    end
endmodule

// --------------------------------------------------------------
// Submodule: binary_stage_register
// Registers the binary value for the next pipeline stage
module binary_stage_register #(parameter DATA_WIDTH=3)(
    input  wire                  clk,
    input  wire [DATA_WIDTH-1:0] din,
    output reg  [DATA_WIDTH-1:0] dout
);
    always @(posedge clk) begin
        dout <= din;
    end
endmodule

// --------------------------------------------------------------
// Submodule: onehot_generator
// Generates a one-hot code from the registered binary input
module onehot_generator #(parameter BINARY_WIDTH=3)(
    input  wire                          clk,
    input  wire [BINARY_WIDTH-1:0]       shift_amount,
    output reg  [2**BINARY_WIDTH-1:0]    onehot_out
);
    always @(posedge clk) begin
        onehot_out <= { {(2**BINARY_WIDTH){1'b0}} } | (1'b1 << shift_amount);
    end
endmodule

// --------------------------------------------------------------
// Submodule: onehot_output_register
// Output register for the final one-hot code (for pipelining)
module onehot_output_register #(parameter ONEHOT_WIDTH=8)(
    input  wire                   clk,
    input  wire [ONEHOT_WIDTH-1:0] din,
    output reg  [ONEHOT_WIDTH-1:0] dout
);
    always @(posedge clk) begin
        dout <= din;
    end
endmodule