//SystemVerilog
// Top-level module: Hierarchical 2-to-1 Synchronous MUX
module sync_2to1_mux (
    input  wire        clk,             // Clock signal
    input  wire [7:0]  data_a,          // Data input A
    input  wire [7:0]  data_b,          // Data input B
    input  wire        sel,             // Selection bit
    output wire [7:0]  q_out            // Registered output
);

    wire [7:0] mux_out;

    // Instantiation of the combinational 2-to-1 multiplexer
    mux2to1_8bit u_mux2to1_8bit (
        .data_a    (data_a),
        .data_b    (data_b),
        .sel       (sel),
        .mux_out   (mux_out)
    );

    // Instantiation of the 8-bit register
    reg8_sync u_reg8_sync (
        .clk       (clk),
        .d         (mux_out),
        .q         (q_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: 8-bit 2-to-1 Multiplexer (Combinational)
// Selects between two 8-bit inputs based on 'sel' signal
// -----------------------------------------------------------------------------
module mux2to1_8bit (
    input  wire [7:0] data_a,      // Input A
    input  wire [7:0] data_b,      // Input B
    input  wire       sel,         // Selection signal
    output wire [7:0] mux_out      // Multiplexer output
);
    assign mux_out = sel ? data_b : data_a;
endmodule

// -----------------------------------------------------------------------------
// Submodule: 8-bit Synchronous Register
// Registers the input data on the rising edge of 'clk'
// -----------------------------------------------------------------------------
module reg8_sync (
    input  wire        clk,        // Clock input
    input  wire [7:0]  d,          // Data input
    output reg  [7:0]  q           // Registered output
);
    always @(posedge clk) begin
        q <= d;
    end
endmodule