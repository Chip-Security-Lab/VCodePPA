//SystemVerilog
module shift_chain #(parameter LEN=4, WIDTH=8) (
    input clk,
    input [WIDTH-1:0] ser_in,
    output [WIDTH-1:0] ser_out
);

// Primary shift register chain
reg [WIDTH-1:0] chain_reg [0:LEN-1];

// Buffer registers for high fanout chain signal
reg [WIDTH-1:0] chain_buf1 [0:LEN-1];
reg [WIDTH-1:0] chain_buf2 [0:LEN-1];

integer idx;
always @(posedge clk) begin
    chain_reg[0] <= ser_in;
    for (idx=1; idx<LEN; idx=idx+1)
        chain_reg[idx] <= chain_reg[idx-1];
end

// Buffer stage 1 for fanout balancing
always @(posedge clk) begin
    for (idx=0; idx<LEN; idx=idx+1)
        chain_buf1[idx] <= chain_reg[idx];
end

// Buffer stage 2 for further fanout balancing
always @(posedge clk) begin
    for (idx=0; idx<LEN; idx=idx+1)
        chain_buf2[idx] <= chain_buf1[idx];
end

wire [WIDTH-1:0] subtrahend;
wire [WIDTH-1:0] minuend;
wire [WIDTH-1:0] diff_result;

// Example connections for demonstration purpose
assign minuend = chain_buf2[LEN-2];
assign subtrahend = chain_buf2[LEN-3];

borrow_subtractor_8bit u_borrow_subtractor_8bit (
    .minuend(minuend),
    .subtrahend(subtrahend),
    .difference(diff_result)
);

assign ser_out = diff_result;

endmodule

module borrow_subtractor_8bit (
    input  [7:0] minuend,
    input  [7:0] subtrahend,
    output [7:0] difference
);

    wire [7:0] borrow;
    wire [7:0] diff_bit;

    // LSB
    assign diff_bit[0] = minuend[0] ^ subtrahend[0];
    assign borrow[0] = (~minuend[0]) & subtrahend[0];

    // Bits 1 to 7
    genvar i;
    generate
        for (i=1; i<8; i=i+1) begin : gen_borrow_sub
            assign diff_bit[i] = minuend[i] ^ subtrahend[i] ^ borrow[i-1];
            assign borrow[i] = ((~minuend[i]) & subtrahend[i]) | (((~minuend[i]) | subtrahend[i]) & borrow[i-1]);
        end
    endgenerate

    assign difference = diff_bit;

endmodule