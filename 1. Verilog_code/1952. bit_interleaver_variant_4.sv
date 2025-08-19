//SystemVerilog
module bit_interleaver #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] data_a,
    input  [WIDTH-1:0] data_b,
    output [2*WIDTH-1:0] interleaved_data,
    input  [WIDTH-1:0] addend_a,
    input  [WIDTH-1:0] addend_b,
    output [WIDTH:0]   sum_out
);
    // Interleaving logic
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: interleave
            assign interleaved_data[2*i]   = data_a[i];
            assign interleaved_data[2*i+1] = data_b[i];
        end
    endgenerate

    // 8-bit Carry Skip Adder (Jump Carry Adder) Implementation
    wire [WIDTH-1:0] propagate_signal;
    wire [WIDTH-1:0] generate_signal;
    wire [WIDTH:0]   carry_chain;

    assign carry_chain[0] = 1'b0;

    genvar j;
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin: pg_gen
            assign propagate_signal[j] = addend_a[j] ^ addend_b[j];
            assign generate_signal[j]  = addend_a[j] & addend_b[j];
        end
    endgenerate

    // Carry Skip Adder Block Partition (4 bits per block)
    localparam BLOCK_SIZE = 4;
    localparam BLOCK_COUNT = WIDTH / BLOCK_SIZE;

    wire [BLOCK_COUNT-1:0] block_propagate;
    wire [BLOCK_COUNT-1:0] block_generate;
    wire [BLOCK_COUNT:0]   block_carry;

    assign block_carry[0] = carry_chain[0];

    // Block propagate & generate logic
    genvar b;
    generate
        for (b = 0; b < BLOCK_COUNT; b = b + 1) begin: block_pg
            assign block_propagate[b] = propagate_signal[b*BLOCK_SIZE+3] &
                                        propagate_signal[b*BLOCK_SIZE+2] &
                                        propagate_signal[b*BLOCK_SIZE+1] &
                                        propagate_signal[b*BLOCK_SIZE];
            assign block_generate[b] = generate_signal[b*BLOCK_SIZE+3] |
                                      (propagate_signal[b*BLOCK_SIZE+3] & generate_signal[b*BLOCK_SIZE+2]) |
                                      (propagate_signal[b*BLOCK_SIZE+3] & propagate_signal[b*BLOCK_SIZE+2] & generate_signal[b*BLOCK_SIZE+1]) |
                                      (propagate_signal[b*BLOCK_SIZE+3] & propagate_signal[b*BLOCK_SIZE+2] & propagate_signal[b*BLOCK_SIZE+1] & generate_signal[b*BLOCK_SIZE]);
        end
    endgenerate

    // Block Carry Logic
    genvar bc;
    generate
        for (bc = 0; bc < BLOCK_COUNT; bc = bc + 1) begin: block_carry_logic
            assign block_carry[bc+1] = block_generate[bc] | (block_propagate[bc] & block_carry[bc]);
        end
    endgenerate

    // Internal carry for each bit
    wire [WIDTH:0] internal_carry;
    assign internal_carry[0] = carry_chain[0];

    // First block (bits 0 to 3)
    assign internal_carry[1] = generate_signal[0] | (propagate_signal[0] & internal_carry[0]);
    assign internal_carry[2] = generate_signal[1] | (propagate_signal[1] & generate_signal[0]) | (propagate_signal[1] & propagate_signal[0] & internal_carry[0]);
    assign internal_carry[3] = generate_signal[2] | (propagate_signal[2] & generate_signal[1]) | (propagate_signal[2] & propagate_signal[1] & generate_signal[0]) | (propagate_signal[2] & propagate_signal[1] & propagate_signal[0] & internal_carry[0]);
    assign internal_carry[4] = generate_signal[3] | (propagate_signal[3] & generate_signal[2]) | (propagate_signal[3] & propagate_signal[2] & generate_signal[1]) |
                               (propagate_signal[3] & propagate_signal[2] & propagate_signal[1] & generate_signal[0]) |
                               (propagate_signal[3] & propagate_signal[2] & propagate_signal[1] & propagate_signal[0] & internal_carry[0]);

    // Second block (bits 4 to 7)
    assign internal_carry[5] = generate_signal[4] | (propagate_signal[4] & internal_carry[4]);
    assign internal_carry[6] = generate_signal[5] | (propagate_signal[5] & generate_signal[4]) | (propagate_signal[5] & propagate_signal[4] & internal_carry[4]);
    assign internal_carry[7] = generate_signal[6] | (propagate_signal[6] & generate_signal[5]) | (propagate_signal[6] & propagate_signal[5] & generate_signal[4]) | (propagate_signal[6] & propagate_signal[5] & propagate_signal[4] & internal_carry[4]);
    assign internal_carry[8] = generate_signal[7] | (propagate_signal[7] & generate_signal[6]) | (propagate_signal[7] & propagate_signal[6] & generate_signal[5]) |
                               (propagate_signal[7] & propagate_signal[6] & propagate_signal[5] & generate_signal[4]) |
                               (propagate_signal[7] & propagate_signal[6] & propagate_signal[5] & propagate_signal[4] & internal_carry[4]);

    // Output sum logic
    genvar s;
    generate
        for (s = 0; s < WIDTH; s = s + 1) begin: sum_out_logic
            assign sum_out[s] = propagate_signal[s] ^ internal_carry[s];
        end
    endgenerate
    assign sum_out[WIDTH] = internal_carry[WIDTH];

endmodule