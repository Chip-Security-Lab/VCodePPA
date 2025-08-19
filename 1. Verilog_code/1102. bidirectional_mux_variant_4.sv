//SystemVerilog
// Top-level module: Hierarchical bidirectional multiplexer
module bidirectional_mux (
    inout wire [7:0] port_a,        // Bidirectional port A
    inout wire [7:0] port_b,        // Bidirectional port B
    inout wire [7:0] common_port,   // Common bidirectional port
    input wire direction,           // Data flow direction control
    input wire active               // Active enable signal
);

    wire [7:0] mux_to_a;
    wire [7:0] mux_to_b;
    wire [7:0] mux_to_common;
    wire       drive_a;
    wire       drive_b;
    wire       drive_common;

    // Output control logic for each direction
    mux_control u_mux_control (
        .active         (active),
        .direction      (direction),
        .drive_a        (drive_a),
        .drive_b        (drive_b),
        .drive_common   (drive_common)
    );

    // Data selection for port A
    port_driver #(
        .WIDTH(8)
    ) u_port_a_driver (
        .drive_en   (drive_a),
        .data_in    (common_port),
        .port_io    (port_a),
        .data_out   (mux_to_a)
    );

    // Data selection for port B
    port_driver #(
        .WIDTH(8)
    ) u_port_b_driver (
        .drive_en   (drive_b),
        .data_in    (common_port),
        .port_io    (port_b),
        .data_out   (mux_to_b)
    );

    // Data selection for common port (with parallel prefix subtractor)
    common_port_driver #(
        .WIDTH(8)
    ) u_common_port_driver (
        .drive_en   (drive_common),
        .direction  (direction),
        .data_a     (port_a),
        .data_b     (port_b),
        .port_io    (common_port),
        .data_out   (mux_to_common)
    );

endmodule

//-----------------------------------------------------------------------------
// mux_control: Generates enable signals for port drivers based on control
//-----------------------------------------------------------------------------
module mux_control (
    input  wire active,
    input  wire direction,
    output wire drive_a,
    output wire drive_b,
    output wire drive_common
);
    // drive_a: Enable driving port_a from common_port when active and !direction
    assign drive_a = active & ~direction;
    // drive_b: Enable driving port_b from common_port when active and direction
    assign drive_b = active & direction;
    // drive_common: Enable driving common_port from port_a or port_b when active
    assign drive_common = active;
endmodule

//-----------------------------------------------------------------------------
// port_driver: Handles tristate and data transfer for port_a or port_b
//-----------------------------------------------------------------------------
module port_driver #(
    parameter WIDTH = 8
)(
    input  wire         drive_en,   // Enable signal to drive port
    input  wire [WIDTH-1:0] data_in, // Data to drive onto port
    inout  wire [WIDTH-1:0] port_io, // Bidirectional port
    output wire [WIDTH-1:0] data_out // Data read from port
);
    assign port_io = drive_en ? data_in : {WIDTH{1'bz}};
    assign data_out = port_io;
endmodule

//-----------------------------------------------------------------------------
// parallel_prefix_subtractor_8: 8-bit Parallel Prefix Subtractor
//-----------------------------------------------------------------------------
module parallel_prefix_subtractor_8 (
    input  wire [7:0] minuend,       // A
    input  wire [7:0] subtrahend,    // B
    input  wire       borrow_in,     // Initial borrow
    output wire [7:0] difference,    // A - B
    output wire       borrow_out     // Final borrow
);

    wire [7:0] generate_borrow;
    wire [7:0] propagate_borrow;
    wire [7:0] borrow;

    // Generate and Propagate signals for borrow
    assign generate_borrow   = ~minuend & subtrahend;
    assign propagate_borrow  = ~(minuend ^ subtrahend);

    // Prefix computation for borrows using Kogge-Stone style
    wire [7:0] gb_stage0, pb_stage0;
    wire [7:0] gb_stage1, pb_stage1;
    wire [7:0] gb_stage2, pb_stage2;

    // Stage 0 (Initial)
    assign gb_stage0 = generate_borrow;
    assign pb_stage0 = propagate_borrow;

    // Stage 1
    assign gb_stage1[0] = gb_stage0[0];
    assign pb_stage1[0] = pb_stage0[0];
    genvar i1;
    generate
        for (i1 = 1; i1 < 8; i1 = i1 + 1) begin : STAGE1
            assign gb_stage1[i1] = gb_stage0[i1] | (pb_stage0[i1] & gb_stage0[i1-1]);
            assign pb_stage1[i1] = pb_stage0[i1] & pb_stage0[i1-1];
        end
    endgenerate

    // Stage 2
    assign gb_stage2[0] = gb_stage1[0];
    assign gb_stage2[1] = gb_stage1[1];
    assign pb_stage2[0] = pb_stage1[0];
    assign pb_stage2[1] = pb_stage1[1];
    genvar i2;
    generate
        for (i2 = 2; i2 < 8; i2 = i2 + 1) begin : STAGE2
            assign gb_stage2[i2] = gb_stage1[i2] | (pb_stage1[i2] & gb_stage1[i2-2]);
            assign pb_stage2[i2] = pb_stage1[i2] & pb_stage1[i2-2];
        end
    endgenerate

    // Stage 3
    wire [7:0] gb_stage3;
    assign gb_stage3[0] = gb_stage2[0];
    assign gb_stage3[1] = gb_stage2[1];
    assign gb_stage3[2] = gb_stage2[2];
    assign gb_stage3[3] = gb_stage2[3];
    genvar i3;
    generate
        for (i3 = 4; i3 < 8; i3 = i3 + 1) begin : STAGE3
            assign gb_stage3[i3] = gb_stage2[i3] | (pb_stage2[i3] & gb_stage2[i3-4]);
        end
    endgenerate

    // Borrow chain
    assign borrow[0] = borrow_in;
    assign borrow[1] = gb_stage3[0] | (pb_stage2[0] & borrow_in);
    assign borrow[2] = gb_stage3[1] | (pb_stage2[1] & borrow[1]);
    assign borrow[3] = gb_stage3[2] | (pb_stage2[2] & borrow[2]);
    assign borrow[4] = gb_stage3[3] | (pb_stage2[3] & borrow[3]);
    assign borrow[5] = gb_stage3[4] | (pb_stage2[4] & borrow[4]);
    assign borrow[6] = gb_stage3[5] | (pb_stage2[5] & borrow[5]);
    assign borrow[7] = gb_stage3[6] | (pb_stage2[6] & borrow[6]);
    assign borrow_out = gb_stage3[7] | (pb_stage2[7] & borrow[7]);

    // Difference
    assign difference = minuend ^ subtrahend ^ {borrow[6:0], borrow_in};

endmodule

//-----------------------------------------------------------------------------
// common_port_driver: Handles tristate and data transfer for common_port
// Uses parallel prefix subtractor for subtraction when direction = 0
//-----------------------------------------------------------------------------
module common_port_driver #(
    parameter WIDTH = 8
)(
    input  wire         drive_en,   // Enable signal to drive common port
    input  wire         direction,  // Direction: 1 for port_a->common, 0 for port_b->common
    input  wire [WIDTH-1:0] data_a, // Data from port_a
    input  wire [WIDTH-1:0] data_b, // Data from port_b
    inout  wire [WIDTH-1:0] port_io, // Bidirectional common port
    output wire [WIDTH-1:0] data_out // Data read from common port
);

    wire [WIDTH-1:0] mux_data;
    wire [WIDTH-1:0] subtract_result;
    wire             subtract_borrow_out;

    parallel_prefix_subtractor_8 u_parallel_prefix_subtractor_8 (
        .minuend    (data_a),
        .subtrahend (data_b),
        .borrow_in  (1'b0),
        .difference (subtract_result),
        .borrow_out (subtract_borrow_out)
    );

    assign mux_data = direction ? data_a : subtract_result;
    assign port_io = drive_en ? mux_data : {WIDTH{1'bz}};
    assign data_out = port_io;

endmodule