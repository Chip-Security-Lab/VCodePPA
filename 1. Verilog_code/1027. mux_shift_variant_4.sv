//SystemVerilog
// Top-level module: mux_shift_hier
module mux_shift_hier #(parameter W=8) (
    input  [W-1:0] data_in,
    input  [1:0]   select,
    output [W-1:0] data_out
);

    // Internal signals for shift results
    wire [W-1:0] passthrough_result;
    wire [W-1:0] shift1_result;
    wire [W-1:0] shift2_result;
    wire [W-1:0] shift4_result;

    // Passthrough submodule instantiation (no shift)
    passthrough_unit #(.W(W)) u_passthrough (
        .din(data_in),
        .dout(passthrough_result)
    );

    // 1-bit shift submodule instantiation
    shift_left_unit #(.W(W), .SHIFT_AMT(1)) u_shift1 (
        .din(data_in),
        .dout(shift1_result)
    );

    // 2-bit shift submodule instantiation
    shift_left_unit #(.W(W), .SHIFT_AMT(2)) u_shift2 (
        .din(data_in),
        .dout(shift2_result)
    );

    // 4-bit shift submodule instantiation
    shift_left_unit #(.W(W), .SHIFT_AMT(4)) u_shift4 (
        .din(data_in),
        .dout(shift4_result)
    );

    // Multiplexer submodule instantiation
    mux_unit #(.W(W)) u_mux (
        .sel(select),
        .in0(passthrough_result),
        .in1(shift1_result),
        .in2(shift2_result),
        .in3(shift4_result),
        .dout(data_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: passthrough_unit
// Function: Pass input to output without modification
// -----------------------------------------------------------------------------
module passthrough_unit #(parameter W=8) (
    input  [W-1:0] din,
    output [W-1:0] dout
);
    assign dout = din;
endmodule

// -----------------------------------------------------------------------------
// Submodule: shift_left_unit
// Function: Shift input left by parameterized amount, fill with zeros
// -----------------------------------------------------------------------------
module shift_left_unit #(parameter W=8, parameter SHIFT_AMT=1) (
    input  [W-1:0] din,
    output [W-1:0] dout
);
    assign dout = {{din[W-SHIFT_AMT-1:0]}, {SHIFT_AMT{1'b0}}};
endmodule

// -----------------------------------------------------------------------------
// Submodule: mux_unit
// Function: 4:1 multiplexer for selecting shifted outputs
// -----------------------------------------------------------------------------
module mux_unit #(parameter W=8) (
    input  [1:0]   sel,
    input  [W-1:0] in0,
    input  [W-1:0] in1,
    input  [W-1:0] in2,
    input  [W-1:0] in3,
    output reg [W-1:0] dout
);
    always @* begin
        case (sel)
            2'b00: dout = in0;
            2'b01: dout = in1;
            2'b10: dout = in2;
            2'b11: dout = in3;
            default: dout = {W{1'b0}};
        endcase
    end
endmodule