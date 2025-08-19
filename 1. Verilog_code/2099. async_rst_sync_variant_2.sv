//SystemVerilog
// Top-level module: Hierarchical asynchronous reset synchronizer with LUT-based 8-bit subtractor
module async_rst_sync #(parameter CH=2) (
    input  wire              clk,
    input  wire              async_rst,
    input  wire [CH-1:0]     ch_in,
    output wire [CH-1:0]     ch_out
);

    // Internal wires for interconnecting submodules
    wire [CH-1:0] sync_stage0;

    // First stage: Synchronizes asynchronous input to clock domain
    sync_stage #(
        .CH(CH)
    ) sync_stage0_inst (
        .clk(clk),
        .rst(async_rst),
        .d_in(ch_in),
        .q_out(sync_stage0)
    );

    // Second stage: Further synchronizes signal to reduce metastability
    sync_stage #(
        .CH(CH)
    ) sync_stage1_inst (
        .clk(clk),
        .rst(async_rst),
        .d_in(sync_stage0),
        .q_out(ch_out)
    );

endmodule

// ---------------------------------------------------------------------------
// Submodule: sync_stage
// Function: One-stage synchronizer with asynchronous reset and LUT-based 8-bit subtractor
// Inputs:
//   - clk: Clock signal
//   - rst: Asynchronous reset signal (active high)
//   - d_in: Data input vector
// Outputs:
//   - q_out: Synchronized data output vector
// ---------------------------------------------------------------------------
module sync_stage #(parameter CH=2) (
    input  wire          clk,
    input  wire          rst,
    input  wire [CH-1:0] d_in,
    output reg  [CH-1:0] q_out
);
    // Internal register for synchronized data
    reg [CH-1:0] synchronized_data;

    // Example signals for 8-bit subtraction
    // (In practice, connect these signals as needed in your design)
    reg  [7:0] lut_sub_a;
    reg  [7:0] lut_sub_b;
    wire [7:0] lut_sub_result;

    // LUT-based 8-bit subtractor instance
    lut_subtractor_8bit lut_subtractor_inst (
        .a(lut_sub_a),
        .b(lut_sub_b),
        .result(lut_sub_result)
    );

    always @(posedge clk or posedge rst) begin
        if (rst)
            synchronized_data <= {CH{1'b0}};
        else
            synchronized_data <= d_in;
    end

    always @(*) begin
        q_out = synchronized_data;
    end

endmodule

// ---------------------------------------------------------------------------
// LUT-based 8-bit Subtractor
// Function: Performs 8-bit subtraction using a lookup table
// Inputs:
//   - a: 8-bit minuend
//   - b: 8-bit subtrahend
// Outputs:
//   - result: 8-bit difference (a - b)
// ---------------------------------------------------------------------------
module lut_subtractor_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output reg  [7:0] result
);
    // Lookup table for 8-bit subtraction (256 x 256 = 65536 entries)
    // For synthesis, use a ROM-based approach for LUT efficiency

    // ROM declaration for subtraction
    reg [7:0] subtraction_lut [0:65535];

    // Initialization (synthesis tools will infer ROM/block RAM)
    initial begin : init_lut
        integer i, j;
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                subtraction_lut[{i[7:0], j[7:0]}] = i - j;
            end
        end
    end

    always @(*) begin
        result = subtraction_lut[{a, b}];
    end

endmodule