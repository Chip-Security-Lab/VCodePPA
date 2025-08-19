//SystemVerilog
module fibonacci_lfsr #(parameter WIDTH = 8) (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [WIDTH-1:0] seed,
    input wire [WIDTH-1:0] polynomial,  // Taps as '1' bits
    output wire [WIDTH-1:0] lfsr_out,
    output wire serial_out
);

    // LFSR register
    reg [WIDTH-1:0] lfsr_reg;

    // Internal signals
    wire feedback_bit;
    wire [WIDTH-1:0] lfsr_next;
    wire [WIDTH-1:0] subtrahend;
    wire [WIDTH-1:0] diff_result;
    wire [WIDTH:0] borrow_chain;

    assign lfsr_out = lfsr_reg;
    assign serial_out = lfsr_reg[0];

    // ----------------------------------------------------------
    // Always block: LFSR register update with reset and enable
    // ----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr_reg <= seed;
        else if (enable)
            lfsr_reg <= diff_result;
    end

    // ----------------------------------------------------------
    // Always block: Compute feedback bit for LFSR
    // ----------------------------------------------------------
    // XOR all tapped bits with '1' in polynomial
    assign feedback_bit = ^(lfsr_reg & polynomial);

    // ----------------------------------------------------------
    // Always block: Compute next LFSR value
    // ----------------------------------------------------------
    assign lfsr_next = {feedback_bit, lfsr_reg[WIDTH-1:1]};

    // ----------------------------------------------------------
    // Always block: Set subtrahend for borrow subtractor (constant 1)
    // ----------------------------------------------------------
    assign subtrahend = {WIDTH{1'b1}};

    // ----------------------------------------------------------
    // Always block: Borrow chain and difference computation
    // ----------------------------------------------------------
    genvar i;
    assign borrow_chain[0] = 1'b0;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_borrow_subtractor
            // Compute difference and borrow for each bit
            assign diff_result[i] = lfsr_next[i] ^ subtrahend[i] ^ borrow_chain[i];
            assign borrow_chain[i+1] = (~lfsr_next[i] & subtrahend[i]) | ((~lfsr_next[i] | subtrahend[i]) & borrow_chain[i]);
        end
    endgenerate

endmodule