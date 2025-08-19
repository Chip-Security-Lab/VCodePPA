//SystemVerilog
module signmag_conv(
    input  wire         clk,
    input  wire         rst_n,
    input  wire signed [15:0] in,
    output wire [15:0]  out
);

// Pipeline Stage 1: Capture input, extract sign, and perform conditional magnitude inversion
reg         sign_pipeline;
reg [14:0]  magnitude_pipeline;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sign_pipeline      <= 1'b0;
        magnitude_pipeline <= 15'd0;
    end else begin
        sign_pipeline      <= in[15];
        magnitude_pipeline <= in[14:0] ^ {15{in[15]}};
    end
end

// Output assignment
assign out = {sign_pipeline, magnitude_pipeline};

endmodule