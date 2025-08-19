//SystemVerilog
module byte_swapping_shifter_valid_ready #(
    parameter DATA_WIDTH = 32
)(
    input                       clk,
    input                       rst_n,
    // Input Valid-Ready handshake
    input  [DATA_WIDTH-1:0]     data_in,
    input  [1:0]                swap_mode_in,
    input                       data_in_valid,
    output                      data_in_ready,
    // Output Valid-Ready handshake
    output reg [DATA_WIDTH-1:0] data_out,
    output reg                  data_out_valid,
    input                       data_out_ready
);

    reg [DATA_WIDTH-1:0] swapped_data_reg;
    reg [1:0]            swap_mode_reg;
    reg                  processing;

    // Intermediate wire declarations for path balancing
    wire swap_mode_is_00, swap_mode_is_01, swap_mode_is_10, swap_mode_is_11;

    assign swap_mode_is_00 = (swap_mode_in == 2'b00);
    assign swap_mode_is_01 = (swap_mode_in == 2'b01);
    assign swap_mode_is_10 = (swap_mode_in == 2'b10);
    assign swap_mode_is_11 = (swap_mode_in == 2'b11);

    // Precompute swapped outputs for each mode
    wire [DATA_WIDTH-1:0] swap_none;
    wire [DATA_WIDTH-1:0] swap_bytes;
    wire [DATA_WIDTH-1:0] swap_words;
    wire [DATA_WIDTH-1:0] swap_bit_reverse;

    assign swap_none  = data_in;

    assign swap_bytes = {data_in[7:0], data_in[15:8], data_in[23:16], data_in[31:24]};

    assign swap_words = {data_in[15:0], data_in[31:16]};

    // Bit reversal for 32 bits, balanced in two levels for path balancing
    wire [31:0] bit_rev_lvl1;
    wire [31:0] bit_rev_lvl2;
    // Level 1: reverse bits within nibbles
    assign bit_rev_lvl1 = {data_in[0], data_in[1], data_in[2], data_in[3],
                           data_in[4], data_in[5], data_in[6], data_in[7],
                           data_in[8], data_in[9], data_in[10], data_in[11],
                           data_in[12], data_in[13], data_in[14], data_in[15],
                           data_in[16], data_in[17], data_in[18], data_in[19],
                           data_in[20], data_in[21], data_in[22], data_in[23],
                           data_in[24], data_in[25], data_in[26], data_in[27],
                           data_in[28], data_in[29], data_in[30], data_in[31]};
    // Level 2: reverse bytes
    assign bit_rev_lvl2 = {bit_rev_lvl1[0],  bit_rev_lvl1[1],  bit_rev_lvl1[2],  bit_rev_lvl1[3],
                           bit_rev_lvl1[4],  bit_rev_lvl1[5],  bit_rev_lvl1[6],  bit_rev_lvl1[7],
                           bit_rev_lvl1[8],  bit_rev_lvl1[9],  bit_rev_lvl1[10], bit_rev_lvl1[11],
                           bit_rev_lvl1[12], bit_rev_lvl1[13], bit_rev_lvl1[14], bit_rev_lvl1[15],
                           bit_rev_lvl1[16], bit_rev_lvl1[17], bit_rev_lvl1[18], bit_rev_lvl1[19],
                           bit_rev_lvl1[20], bit_rev_lvl1[21], bit_rev_lvl1[22], bit_rev_lvl1[23],
                           bit_rev_lvl1[24], bit_rev_lvl1[25], bit_rev_lvl1[26], bit_rev_lvl1[27],
                           bit_rev_lvl1[28], bit_rev_lvl1[29], bit_rev_lvl1[30], bit_rev_lvl1[31]};
    assign swap_bit_reverse = bit_rev_lvl2;

    // Balanced multiplexer logic for swapped data
    wire [DATA_WIDTH-1:0] swapped_data_comb_lvl1_0, swapped_data_comb_lvl1_1;
    wire [DATA_WIDTH-1:0] swapped_data_comb;

    // Level 1 multiplexing
    assign swapped_data_comb_lvl1_0 = swap_mode_is_00 ? swap_none  : swap_bytes;
    assign swapped_data_comb_lvl1_1 = swap_mode_is_10 ? swap_words : swap_bit_reverse;
    // Level 2 multiplexing
    assign swapped_data_comb = swap_mode_in[1] ? swapped_data_comb_lvl1_1 : swapped_data_comb_lvl1_0;

    // Input handshake: ready when not processing or output is accepted
    assign data_in_ready = (~processing) | (data_out_valid & data_out_ready);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            swapped_data_reg <= {DATA_WIDTH{1'b0}};
            swap_mode_reg    <= 2'b00;
            data_out         <= {DATA_WIDTH{1'b0}};
            data_out_valid   <= 1'b0;
            processing       <= 1'b0;
        end else begin
            // Accept new input if ready
            if (data_in_ready & data_in_valid) begin
                swapped_data_reg <= swapped_data_comb;
                swap_mode_reg    <= swap_mode_in;
                data_out         <= swapped_data_comb;
                data_out_valid   <= 1'b1;
                processing       <= 1'b1;
            end else if (data_out_valid & data_out_ready) begin
                data_out_valid   <= 1'b0;
                processing       <= 1'b0;
            end
        end
    end

endmodule