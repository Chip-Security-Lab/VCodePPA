//SystemVerilog
// Top-level mux_shift module with hierarchical submodules

module mux_shift #(parameter W=8) (
    input  [W-1:0] data_in,
    input  [1:0]   select,
    output [W-1:0] data_out
);

    // Internal wires for submodule outputs
    wire [W-1:0] pass_through_out;
    wire [W-1:0] shift_left1_out;
    wire [W-1:0] shift_left2_out;
    wire [W-1:0] shift_left4_out;

    // Instantiate pass-through submodule
    mux_shift_passthrough #(.W(W)) u_passthrough (
        .data_in(data_in),
        .data_out(pass_through_out)
    );

    // Instantiate shift left by 1 submodule
    mux_shift_left1 #(.W(W)) u_shift_left1 (
        .data_in(data_in),
        .data_out(shift_left1_out)
    );

    // Instantiate shift left by 2 submodule
    mux_shift_left2 #(.W(W)) u_shift_left2 (
        .data_in(data_in),
        .data_out(shift_left2_out)
    );

    // Instantiate shift left by 4 submodule
    mux_shift_left4 #(.W(W)) u_shift_left4 (
        .data_in(data_in),
        .data_out(shift_left4_out)
    );

    // Instantiate 4-to-1 multiplexer submodule
    mux_shift_mux4 #(.W(W)) u_mux4 (
        .in0(pass_through_out),
        .in1(shift_left1_out),
        .in2(shift_left2_out),
        .in3(shift_left4_out),
        .sel(select),
        .mux_out(data_out)
    );

endmodule

// Pass-through submodule: outputs input as-is
module mux_shift_passthrough #(parameter W=8) (
    input  [W-1:0] data_in,
    output [W-1:0] data_out
);
    assign data_out = data_in;
endmodule

// Shift-left-by-1 submodule: logical left shift by 1, fill LSB with 0
module mux_shift_left1 #(parameter W=8) (
    input  [W-1:0] data_in,
    output [W-1:0] data_out
);
    assign data_out = {data_in[W-2:0], 1'b0};
endmodule

// Shift-left-by-2 submodule: logical left shift by 2, fill LSBs with 0
module mux_shift_left2 #(parameter W=8) (
    input  [W-1:0] data_in,
    output [W-1:0] data_out
);
    assign data_out = {data_in[W-3:0], 2'b00};
endmodule

// Shift-left-by-4 submodule: logical left shift by 4, fill LSBs with 0
module mux_shift_left4 #(parameter W=8) (
    input  [W-1:0] data_in,
    output [W-1:0] data_out
);
    assign data_out = {data_in[W-5:0], 4'b0000};
endmodule

// 4-to-1 multiplexer submodule for mux_shift
module mux_shift_mux4 #(parameter W=8) (
    input  [W-1:0] in0,
    input  [W-1:0] in1,
    input  [W-1:0] in2,
    input  [W-1:0] in3,
    input  [1:0]   sel,
    output reg [W-1:0] mux_out
);
    always @(*) begin
        case (sel)
            2'd0: mux_out = in0;
            2'd1: mux_out = in1;
            2'd2: mux_out = in2;
            2'd3: mux_out = in3;
            default: mux_out = {W{1'b0}};
        endcase
    end
endmodule