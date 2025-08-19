//SystemVerilog
module decoder_gated #(WIDTH=3) (
    input clk,
    input clk_en,
    input [WIDTH-1:0] addr,
    output [7:0] decoded
);

    wire [7:0] decoder_out;
    wire [7:0] decoded_next;

    decoder_core #(.WIDTH(WIDTH)) u_decoder_core (
        .addr(addr),
        .decoded(decoder_out)
    );

    decoder_reg #(.WIDTH(WIDTH)) u_decoder_reg (
        .clk(clk),
        .clk_en(clk_en),
        .decoder_in(decoder_out),
        .decoded(decoded)
    );

endmodule

module decoder_core #(WIDTH=3) (
    input [WIDTH-1:0] addr,
    output [7:0] decoded
);
    assign decoded = 1 << addr;
endmodule

module decoder_reg #(WIDTH=3) (
    input clk,
    input clk_en,
    input [7:0] decoder_in,
    output reg [7:0] decoded
);
    always @(posedge clk) begin
        decoded <= clk_en ? decoder_in : decoded;
    end
endmodule