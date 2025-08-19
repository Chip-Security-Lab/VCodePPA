//SystemVerilog
module rng_shiftxor_6_axi_stream (
    input              clk,
    input              rst,
    input              axi_stream_tready,
    output reg         axi_stream_tvalid,
    output reg [7:0]   axi_stream_tdata,
    output reg         axi_stream_tlast
);
    reg [7:0] random_state_reg;
    wire      parity_mix_internal = ^(random_state_reg[7:4]);
    wire [7:0] next_random_state;
    wire [7:0] mult_output;

    // Baugh-Wooley multiplication for randomization
    baugh_wooley_mult8 bw_mult_inst (
        .a({random_state_reg[6:0], parity_mix_internal}),
        .b(8'b10110101),
        .product(mult_output)
    );

    assign next_random_state = mult_output;

    // Data valid handshake logic
    reg generate_new_random;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            random_state_reg   <= 8'hF0;
            axi_stream_tvalid  <= 1'b0;
            axi_stream_tdata   <= 8'b0;
            axi_stream_tlast   <= 1'b0;
            generate_new_random <= 1'b1;
        end else begin
            // Generate new random number when tready is high and tvalid is asserted
            if (axi_stream_tvalid && axi_stream_tready) begin
                random_state_reg   <= next_random_state;
                axi_stream_tdata   <= next_random_state;
                axi_stream_tvalid  <= 1'b1;
                axi_stream_tlast   <= 1'b0;
                generate_new_random <= 1'b0;
            end else if (!axi_stream_tvalid) begin
                axi_stream_tdata   <= random_state_reg;
                axi_stream_tvalid  <= 1'b1;
                axi_stream_tlast   <= 1'b0;
                generate_new_random <= 1'b0;
            end else if (!axi_stream_tready && axi_stream_tvalid) begin
                // Hold current data until tready is high
                axi_stream_tvalid  <= 1'b1;
                axi_stream_tlast   <= 1'b0;
                generate_new_random <= 1'b0;
            end
            // Optional: assert tlast for single-beat stream or for end-of-packet signaling
            // axi_stream_tlast <= /* logic for tlast if required */;
        end
    end
endmodule

module baugh_wooley_mult8(
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] product
);
    wire [15:0] full_product;

    // Baugh-Wooley partial products and sign extension
    wire [7:0] pp[7:0];

    assign pp[0] = a[0] ? b : 8'b0;
    assign pp[1] = a[1] ? b : 8'b0;
    assign pp[2] = a[2] ? b : 8'b0;
    assign pp[3] = a[3] ? b : 8'b0;
    assign pp[4] = a[4] ? b : 8'b0;
    assign pp[5] = a[5] ? b : 8'b0;
    assign pp[6] = a[6] ? b : 8'b0;
    assign pp[7] = a[7] ? b : 8'b0;

    // Baugh-Wooley sign extension and bit inversion
    wire [15:0] baugh_wooley_pp[7:0];

    assign baugh_wooley_pp[0] = {8'b0, pp[0]};
    assign baugh_wooley_pp[1] = {7'b0, pp[1], 1'b0};
    assign baugh_wooley_pp[2] = {6'b0, pp[2], 2'b0};
    assign baugh_wooley_pp[3] = {5'b0, pp[3], 3'b0};
    assign baugh_wooley_pp[4] = {4'b0, pp[4], 4'b0};
    assign baugh_wooley_pp[5] = {3'b0, pp[5], 5'b0};
    assign baugh_wooley_pp[6] = {2'b0, pp[6], 6'b0};
    assign baugh_wooley_pp[7] = {1'b0, pp[7], 7'b0};

    // Baugh-Wooley correction terms for sign bits
    wire [15:0] correction;
    assign correction = { {(8){a[7] & b[7]}}, 8'b0 };

    // Final summation
    assign full_product = baugh_wooley_pp[0]
                        + baugh_wooley_pp[1]
                        + baugh_wooley_pp[2]
                        + baugh_wooley_pp[3]
                        + baugh_wooley_pp[4]
                        + baugh_wooley_pp[5]
                        + baugh_wooley_pp[6]
                        + baugh_wooley_pp[7]
                        + correction;

    assign product = full_product[7:0];
endmodule