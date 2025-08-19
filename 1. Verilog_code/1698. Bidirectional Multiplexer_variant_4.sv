//SystemVerilog
// Direction control submodule
module direction_control(
    input direction,
    input enable,
    output reg dir_a,
    output reg dir_b
);
    always @(*) begin
        dir_a = enable & ~direction;
        dir_b = enable & direction;
    end
endmodule

// Port A submodule
module port_a_interface(
    inout [7:0] port_a,
    input [7:0] data_in,
    input dir_a,
    output [7:0] data_out
);
    assign port_a = dir_a ? 8'bz : data_in;
    assign data_out = port_a;
endmodule

// Port B submodule
module port_b_interface(
    inout [7:0] port_b,
    input [7:0] data_in,
    input dir_b,
    output [7:0] data_out
);
    assign port_b = dir_b ? 8'bz : data_in;
    assign data_out = port_b;
endmodule

// Top-level bidirectional mux module
module bidir_mux(
    inout [7:0] port_a,
    inout [7:0] port_b,
    input direction,
    input enable
);
    wire dir_a, dir_b;
    wire [7:0] port_a_in, port_b_in;
    wire [7:0] port_a_out, port_b_out;

    direction_control dir_ctrl(
        .direction(direction),
        .enable(enable),
        .dir_a(dir_a),
        .dir_b(dir_b)
    );

    port_a_interface port_a_if(
        .port_a(port_a),
        .data_in(port_b_in),
        .dir_a(dir_a),
        .data_out(port_a_in)
    );

    port_b_interface port_b_if(
        .port_b(port_b),
        .data_in(port_a_in),
        .dir_b(dir_b),
        .data_out(port_b_in)
    );
endmodule