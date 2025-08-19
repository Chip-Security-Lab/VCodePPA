//SystemVerilog
module MuxParity #(parameter W=8) (
    input [3:0][W:0] data_ch, // [W] is parity
    input [1:0] sel,
    output [W:0] data_out
);

    wire [W:0] mux_out;
    
    // Multiplexer submodule
    Mux4to1 #(.WIDTH(W)) mux_inst (
        .data_in(data_ch),
        .sel(sel),
        .data_out(mux_out)
    );
    
    // Parity generator submodule
    ParityGen #(.WIDTH(W)) parity_inst (
        .data_in(mux_out[W-1:0]),
        .parity_out(data_out[W]),
        .data_out(data_out[W-1:0])
    );

endmodule

// 4-to-1 Multiplexer submodule
module Mux4to1 #(parameter WIDTH=8) (
    input [3:0][WIDTH:0] data_in,
    input [1:0] sel,
    output reg [WIDTH:0] data_out
);
    always @(*) begin
        data_out = data_in[sel];
    end
endmodule

// Parity Generator submodule with look-ahead carry
module ParityGen #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    output parity_out,
    output [WIDTH-1:0] data_out
);
    wire [WIDTH-1:0] carry_chain;
    wire [WIDTH-1:0] parity_bits;
    
    // Generate look-ahead carry chain
    assign carry_chain[0] = data_in[0];
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : carry_gen
            assign carry_chain[i] = carry_chain[i-1] ^ data_in[i];
        end
    endgenerate
    
    // Generate parity bits
    assign parity_bits = data_in ^ {1'b0, carry_chain[WIDTH-2:0]};
    
    assign data_out = data_in;
    assign parity_out = carry_chain[WIDTH-1];
endmodule