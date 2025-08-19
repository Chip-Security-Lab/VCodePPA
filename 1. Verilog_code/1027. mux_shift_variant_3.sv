//SystemVerilog
// Hierarchical and modular mux_shift design

// ------------------------------------------------------------------------
// Top-level mux_shift module: Hierarchically instantiates shift and mux modules
// ------------------------------------------------------------------------
module mux_shift #(parameter W=8) (
    input  [W-1:0] din,
    input  [1:0]   sel,
    output [W-1:0] dout
);

    // Intermediate signals for the shifted outputs
    wire [W-1:0] shift_out_0;
    wire [W-1:0] shift_out_1;
    wire [W-1:0] shift_out_2;
    wire [W-1:0] shift_out_3;

    // Shifting operation group
    shift_group #(.W(W)) u_shift_group (
        .data_in(din),
        .shift0_out(shift_out_0),
        .shift1_out(shift_out_1),
        .shift2_out(shift_out_2),
        .shift3_out(shift_out_3)
    );

    // Multiplexer operation group
    mux_group #(.W(W)) u_mux_group (
        .mux_in0(shift_out_0),
        .mux_in1(shift_out_1),
        .mux_in2(shift_out_2),
        .mux_in3(shift_out_3),
        .mux_sel(sel),
        .mux_out(dout)
    );

endmodule

// ------------------------------------------------------------------------
// shift_group: Groups all shift operations (pass, shift1, shift2, shift3)
// ------------------------------------------------------------------------
module shift_group #(parameter W=8) (
    input  [W-1:0] data_in,
    output [W-1:0] shift0_out,
    output [W-1:0] shift1_out,
    output [W-1:0] shift2_out,
    output [W-1:0] shift3_out
);
    // Pass-through (no shift)
    shift_pass #(.W(W)) u_shift_pass (
        .din(data_in),
        .dout(shift0_out)
    );
    // Shift left by 1 (fill LSB with 0)
    shift_left_1 #(.W(W)) u_shift_left_1 (
        .din(data_in),
        .dout(shift1_out)
    );
    // Shift left by 2 (fill LSBs with 0)
    shift_left_2 #(.W(W)) u_shift_left_2 (
        .din(data_in),
        .dout(shift2_out)
    );
    // Shift left by 4 (fill LSBs with 0)
    shift_left_4 #(.W(W)) u_shift_left_4 (
        .din(data_in),
        .dout(shift3_out)
    );
endmodule

// ------------------------------------------------------------------------
// mux_group: 4-to-1 multiplexer for W-bit buses
// ------------------------------------------------------------------------
module mux_group #(parameter W=8) (
    input  [W-1:0] mux_in0,
    input  [W-1:0] mux_in1,
    input  [W-1:0] mux_in2,
    input  [W-1:0] mux_in3,
    input  [1:0]   mux_sel,
    output [W-1:0] mux_out
);
    mux4to1 #(.W(W)) u_mux4to1 (
        .in0(mux_in0),
        .in1(mux_in1),
        .in2(mux_in2),
        .in3(mux_in3),
        .sel(mux_sel),
        .dout(mux_out)
    );
endmodule

// ------------------------------------------------------------------------
// shift_pass: Pass-through (no shift)
// ------------------------------------------------------------------------
module shift_pass #(parameter W=8) (
    input  [W-1:0] din,
    output [W-1:0] dout
);
    // Directly assign input to output
    assign dout = din;
endmodule

// ------------------------------------------------------------------------
// shift_left_1: Shift input left by 1, fill LSB with 0
// ------------------------------------------------------------------------
module shift_left_1 #(parameter W=8) (
    input  [W-1:0] din,
    output [W-1:0] dout
);
    // Shift left by 1
    assign dout = {din[W-2:0], 1'b0};
endmodule

// ------------------------------------------------------------------------
// shift_left_2: Shift input left by 2, fill LSBs with 0
// ------------------------------------------------------------------------
module shift_left_2 #(parameter W=8) (
    input  [W-1:0] din,
    output [W-1:0] dout
);
    // Shift left by 2
    assign dout = {din[W-3:0], 2'b00};
endmodule

// ------------------------------------------------------------------------
// shift_left_4: Shift input left by 4, fill LSBs with 0
// ------------------------------------------------------------------------
module shift_left_4 #(parameter W=8) (
    input  [W-1:0] din,
    output [W-1:0] dout
);
    // Shift left by 4
    assign dout = {din[W-5:0], 4'b0000};
endmodule

// ------------------------------------------------------------------------
// mux4to1: 4-to-1 multiplexer for W-bit buses
// ------------------------------------------------------------------------
module mux4to1 #(parameter W=8) (
    input  [W-1:0] in0,
    input  [W-1:0] in1,
    input  [W-1:0] in2,
    input  [W-1:0] in3,
    input  [1:0]   sel,
    output [W-1:0] dout
);
    // Multiplex the four inputs based on select
    assign dout = (sel == 2'd0) ? in0 :
                  (sel == 2'd1) ? in1 :
                  (sel == 2'd2) ? in2 :
                                   in3;
endmodule