//SystemVerilog
module byte_reverser #(
    parameter BYTES = 4  // Default 32-bit word
)(
    input wire clk,
    input wire rst_n,
    input wire reverse_en,
    input wire [BYTES*8-1:0] data_in,
    output reg [BYTES*8-1:0] data_out
);

    wire [BYTES*8-1:0] reversed_data;
    wire [BYTES*8-1:0] muxed_data;

    // Pure combinational byte reversal logic in a separate module
    byte_reverse_comb #(
        .BYTES(BYTES)
    ) u_byte_reverse_comb (
        .data_in(data_in),
        .data_out(reversed_data)
    );

    // Combinational mux for selecting between reversed and original data
    assign muxed_data = reverse_en ? reversed_data : data_in;

    // Sequential logic: registers the output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= { (BYTES*8){1'b0} };
        end else begin
            data_out <= muxed_data;
        end
    end

endmodule

// Combinational byte reversal module
module byte_reverse_comb #(
    parameter BYTES = 4
)(
    input wire [BYTES*8-1:0] data_in,
    output wire [BYTES*8-1:0] data_out
);
    genvar i;
    generate
        for (i = 0; i < BYTES; i = i + 1) begin : gen_byte_reverse
            assign data_out[i*8 +: 8] = data_in[(BYTES-1-i)*8 +: 8];
        end
    endgenerate
endmodule