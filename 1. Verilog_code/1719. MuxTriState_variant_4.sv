//SystemVerilog
module MuxTriState #(parameter W=8, N=4) (
    inout [W-1:0] bus,
    input [W-1:0] data_in [0:N-1],
    input [N-1:0] oe
);

    wire [W-1:0] tri_state_out [0:N-1];
    wire [N-1:0] valid;
    
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin: gen_tri_buf
            TriStateBuffer #(.WIDTH(W)) tri_buf_inst (
                .data_in(data_in[i]),
                .oe(oe[i]),
                .data_out(tri_state_out[i]),
                .valid(valid[i])
            );
        end
    endgenerate

    BusArbiter #(.WIDTH(W), .NUM_PORTS(N)) arbiter_inst (
        .tri_state_in(tri_state_out),
        .valid(valid),
        .bus_out(bus)
    );

endmodule

module TriStateBuffer #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input oe,
    output [WIDTH-1:0] data_out,
    output valid
);
    assign data_out = oe ? data_in : {WIDTH{1'bz}};
    assign valid = oe;
endmodule

module BusArbiter #(parameter WIDTH=8, NUM_PORTS=4) (
    input [WIDTH-1:0] tri_state_in [0:NUM_PORTS-1],
    input [NUM_PORTS-1:0] valid,
    output [WIDTH-1:0] bus_out
);
    
    wire [WIDTH-1:0] bus_reg;
    wire [NUM_PORTS-1:0] priority_sel;
    
    // Priority encoder with binary complement subtraction
    wire [NUM_PORTS-1:0] valid_comp;
    wire [NUM_PORTS-1:0] valid_comp_plus1;
    wire [NUM_PORTS-1:0] valid_comp_result;
    
    assign valid_comp = ~valid;
    assign valid_comp_plus1 = valid_comp + 1'b1;
    assign valid_comp_result = valid_comp_plus1 & valid;
    
    assign priority_sel = valid_comp_result;
    
    // Multiplexer
    wire [WIDTH-1:0] mux_out [0:NUM_PORTS-1];
    assign mux_out[0] = priority_sel[0] ? tri_state_in[0] : {WIDTH{1'bz}};
    genvar i;
    generate
        for (i = 1; i < NUM_PORTS; i = i + 1) begin: gen_mux
            assign mux_out[i] = priority_sel[i] ? tri_state_in[i] : mux_out[i-1];
        end
    endgenerate
    
    assign bus_out = mux_out[NUM_PORTS-1];
endmodule