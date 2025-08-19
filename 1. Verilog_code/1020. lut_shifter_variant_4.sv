//SystemVerilog
// Top-level Module: Hierarchical LUT-based Shifter

module lut_shifter #(parameter W=4) (
    input  wire [W-1:0] data_in,
    input  wire [1:0]   shift_amt,
    output wire [W-1:0] data_out
);

    // Internal signals for each shift operation
    wire [W-1:0] shift0_out;
    wire [W-1:0] shift1_out;
    wire [W-1:0] shift2_out;
    wire [W-1:0] shift3_out;

    // Submodule: No shift (pass-through)
    lut_shift0 #(.W(W)) u_shift0 (
        .data_in (data_in),
        .data_out(shift0_out)
    );

    // Submodule: Shift left by 1
    lut_shift1 #(.W(W)) u_shift1 (
        .data_in (data_in),
        .data_out(shift1_out)
    );

    // Submodule: Shift left by 2
    lut_shift2 #(.W(W)) u_shift2 (
        .data_in (data_in),
        .data_out(shift2_out)
    );

    // Submodule: Shift left by 3
    lut_shift3 #(.W(W)) u_shift3 (
        .data_in (data_in),
        .data_out(shift3_out)
    );

    // Submodule: Shift Amount Multiplexer
    lut_shift_mux #(.W(W)) u_shift_mux (
        .shift_amt (shift_amt),
        .shift0_in (shift0_out),
        .shift1_in (shift1_out),
        .shift2_in (shift2_out),
        .shift3_in (shift3_out),
        .data_out  (data_out)
    );

endmodule

// ---------------------------------------------------------------------------
// Submodule: lut_shift0
// Function: Pass-through (no shift)
// ---------------------------------------------------------------------------
module lut_shift0 #(parameter W=4) (
    input  wire [W-1:0] data_in,
    output wire [W-1:0] data_out
);
    assign data_out = data_in;
endmodule

// ---------------------------------------------------------------------------
// Submodule: lut_shift1
// Function: Logical left shift by 1 (fill LSB with 0)
// ---------------------------------------------------------------------------
module lut_shift1 #(parameter W=4) (
    input  wire [W-1:0] data_in,
    output wire [W-1:0] data_out
);
    assign data_out = {data_in[W-2:0], 1'b0};
endmodule

// ---------------------------------------------------------------------------
// Submodule: lut_shift2
// Function: Logical left shift by 2 (fill LSBs with 0)
// ---------------------------------------------------------------------------
module lut_shift2 #(parameter W=4) (
    input  wire [W-1:0] data_in,
    output wire [W-1:0] data_out
);
    assign data_out = {data_in[W-3:0], 2'b00};
endmodule

// ---------------------------------------------------------------------------
// Submodule: lut_shift3
// Function: Logical left shift by 3 (fill LSBs with 0)
// ---------------------------------------------------------------------------
module lut_shift3 #(parameter W=4) (
    input  wire [W-1:0] data_in,
    output wire [W-1:0] data_out
);
    assign data_out = {data_in[W-4:0], 3'b000};
endmodule

// ---------------------------------------------------------------------------
// Submodule: lut_shift_mux
// Function: Selects the shifted output based on shift_amt
// ---------------------------------------------------------------------------
module lut_shift_mux #(parameter W=4) (
    input  wire [1:0]   shift_amt,
    input  wire [W-1:0] shift0_in,
    input  wire [W-1:0] shift1_in,
    input  wire [W-1:0] shift2_in,
    input  wire [W-1:0] shift3_in,
    output reg  [W-1:0] data_out
);
    always @(*) begin
        case (shift_amt)
            2'd0: data_out = shift0_in;
            2'd1: data_out = shift1_in;
            2'd2: data_out = shift2_in;
            2'd3: data_out = shift3_in;
            default: data_out = {W{1'b0}};
        endcase
    end
endmodule