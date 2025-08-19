//SystemVerilog
// Control module
module bidir_control(
    input direction,
    input enable,
    output a_to_b_en,
    output b_to_a_en
);
    assign a_to_b_en = enable && direction;
    assign b_to_a_en = enable && !direction;
endmodule

// Data path module
module bidir_datapath(
    input [7:0] port_a_in,
    input [7:0] port_b_in,
    input a_to_b_en,
    input b_to_a_en,
    output reg [7:0] a_to_b_reg,
    output reg [7:0] b_to_a_reg
);
    always @(*) begin
        if (a_to_b_en) begin
            a_to_b_reg = port_a_in;
        end
        if (b_to_a_en) begin
            b_to_a_reg = port_b_in;
        end
    end
endmodule

// Output driver module
module bidir_driver(
    input [7:0] a_to_b_reg,
    input [7:0] b_to_a_reg,
    input a_to_b_en,
    input b_to_a_en,
    output [7:0] port_a_out,
    output [7:0] port_b_out
);
    assign port_a_out = b_to_a_en ? b_to_a_reg : 8'bz;
    assign port_b_out = a_to_b_en ? a_to_b_reg : 8'bz;
endmodule

// Top level module
module bidir_mux(
    inout [7:0] port_a,
    inout [7:0] port_b,
    input direction,
    input enable
);
    // Internal signals
    wire a_to_b_en;
    wire b_to_a_en;
    wire [7:0] a_to_b_reg;
    wire [7:0] b_to_a_reg;
    
    // Module instances
    bidir_control control_inst(
        .direction(direction),
        .enable(enable),
        .a_to_b_en(a_to_b_en),
        .b_to_a_en(b_to_a_en)
    );
    
    bidir_datapath datapath_inst(
        .port_a_in(port_a),
        .port_b_in(port_b),
        .a_to_b_en(a_to_b_en),
        .b_to_a_en(b_to_a_en),
        .a_to_b_reg(a_to_b_reg),
        .b_to_a_reg(b_to_a_reg)
    );
    
    bidir_driver driver_inst(
        .a_to_b_reg(a_to_b_reg),
        .b_to_a_reg(b_to_a_reg),
        .a_to_b_en(a_to_b_en),
        .b_to_a_en(b_to_a_en),
        .port_a_out(port_a),
        .port_b_out(port_b)
    );
endmodule