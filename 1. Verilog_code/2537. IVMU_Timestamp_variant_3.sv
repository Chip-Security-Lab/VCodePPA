//SystemVerilog
module IVMU_Timestamp #(parameter TS_W=16) (
    input clk,
    input [TS_W-1:0] ts [0:3],
    output reg [1:0] sel
);

// Ensure TS_W is a multiple of 2 for the CLA implementation
// This is a constraint imposed by the 2-bit block requirement
// synthesis translate_off
initial begin
    if (TS_W % 2 != 0) begin
        $fatal(1, "TS_W must be a multiple of 2 for this CLA implementation");
    end
end
// synthesis translate_on


// Instantiate TS_W-bit CLA adders for subtraction
// ts[0] - ts[1] = ts[0] + (~ts[1]) + 1
wire [TS_W-1:0] sub_ts0_ts1_sum;
wire sub_ts0_ts1_cout;
cla_adder_TS_W #(TS_W) u_sub_ts0_ts1 (
    .a(ts[0]),
    .b(~ts[1]),
    .cin(1'b1),
    .sum(sub_ts0_ts1_sum),
    .cout(sub_ts0_ts1_cout)
);
// Result is TS_W+1 bits to capture the carry-out
wire [TS_W:0] sub_ts0_ts1_res = {sub_ts0_ts1_cout, sub_ts0_ts1_sum};


// ts[0] - ts[2] = ts[0] + (~ts[2]) + 1
wire [TS_W-1:0] sub_ts0_ts2_sum;
wire sub_ts0_ts2_cout;
cla_adder_TS_W #(TS_W) u_sub_ts0_ts2 (
    .a(ts[0]),
    .b(~ts[2]),
    .cin(1'b1),
    .sum(sub_ts0_ts2_sum),
    .cout(sub_ts0_ts2_cout)
);
wire [TS_W:0] sub_ts0_ts2_res = {sub_ts0_ts2_cout, sub_ts0_ts2_sum};


// ts[1] - ts[2] = ts[1] + (~ts[2]) + 1
wire [TS_W-1:0] sub_ts1_ts2_sum;
wire sub_ts1_ts2_cout;
cla_adder_TS_W #(TS_W) u_sub_ts1_ts2 (
    .a(ts[1]),
    .b(~ts[2]),
    .cin(1'b1),
    .sum(sub_ts1_ts2_sum),
    .cout(sub_ts1_ts2_cout)
);
wire [TS_W:0] sub_ts1_ts2_res = {sub_ts1_ts2_cout, sub_ts1_ts2_sum};


// Wires for comparison results (A < B) - Combinational outputs
// A < B (unsigned) is true if the carry-out (MSB of sub_res) is 0
wire lt_ts0_ts1_comb; // ts[0] < ts[1]
wire lt_ts0_ts2_comb; // ts[0] < ts[2]
wire lt_ts1_ts2_comb; // ts[1] < ts[2]

assign lt_ts0_ts1_comb = ~sub_ts0_ts1_res[TS_W];
assign lt_ts0_ts2_comb = ~sub_ts0_ts2_res[TS_W];
assign lt_ts1_ts2_comb = ~sub_ts1_ts2_res[TS_W];

// Pipelined registers for comparison results
reg lt_ts0_ts1_pipe;
reg lt_ts0_ts2_pipe;
reg lt_ts1_ts2_pipe;

// Register the comparison results
always @(posedge clk) begin
    lt_ts0_ts1_pipe <= lt_ts0_ts1_comb;
    lt_ts0_ts2_pipe <= lt_ts0_ts2_comb;
    lt_ts1_ts2_pipe <= lt_ts1_ts2_comb;
end

// Use the pipelined comparison results to determine the minimum
always @(posedge clk) begin
    // The comparisons are based on the timestamp values from two cycles ago
    // due to the pipeline register stage.
    if (lt_ts0_ts1_pipe) begin // if ts[0] < ts[1] (from previous cycle's comparison)
        if (lt_ts0_ts2_pipe) begin // if ts[0] < ts[2] (from previous cycle's comparison)
            sel <= 2'd0; // ts[0] is minimum
        end else begin // else (ts[0] >= ts[2]) (from previous cycle's comparison)
            sel <= 2'd2; // ts[2] is minimum
        end
    end else begin // else (ts[0] >= ts[1]) (from previous cycle's comparison)
        if (lt_ts1_ts2_pipe) begin // if ts[1] < ts[2] (from previous cycle's comparison)
            sel <= 2'd1; // ts[1] is minimum
        end else begin // else (ts[1] >= ts[2]) (from previous cycle's comparison)
            sel <= 2'd2; // ts[2] is minimum
        end
    end
end

endmodule


// TS_W-bit adder using chained 2-bit CLA blocks
// Requires TS_W to be a multiple of 2
module cla_adder_TS_W #(parameter TS_W=16) (
    input [TS_W-1:0] a,
    input [TS_W-1:0] b,
    input cin,
    output [TS_W-1:0] sum,
    output cout
);

    // Number of 2-bit blocks
    localparam NUM_BLOCKS = TS_W / 2;

    // Internal carries between blocks
    wire [NUM_BLOCKS:0] carries; // carries[0] is cin, carries[NUM_BLOCKS] is cout

    assign carries[0] = cin;

    // Instantiate 2-bit CLA blocks
    genvar i;
    generate
        for (i = 0; i < NUM_BLOCKS; i = i + 1) begin : block_gen
            cla_adder_2bit u_cla_2bit (
                .a(a[2*i + 1 : 2*i]),
                .b(b[2*i + 1 : 2*i]),
                .cin(carries[i]),
                .sum(sum[2*i + 1 : 2*i]),
                .cout(carries[i+1])
            );
        end
    endgenerate

    assign cout = carries[NUM_BLOCKS];

endmodule


// 2-bit Carry-Lookahead Adder block
module cla_adder_2bit (
    input [1:0] a,
    input [1:0] b,
    input cin,
    output [1:0] sum,
    output cout
);
    // Generate and Propagate signals for each bit
    wire p0, g0;
    wire p1, g1;

    // Carry signals
    wire c1; // Carry out of bit 0, carry in to bit 1

    // Bit 0 (LSB)
    assign p0 = a[0] ^ b[0]; // Propagate
    assign g0 = a[0] & b[0]; // Generate

    // Bit 1 (MSB)
    assign p1 = a[1] ^ b[1]; // Propagate
    assign g1 = a[1] & b[1]; // Generate

    // Carry-lookahead logic
    // c1 = g0 | (p0 & cin)
    // cout = c2 = g1 | (p1 & c1)
    assign c1   = g0 | (p0 & cin);
    assign cout = g1 | (p1 & c1);

    // Sum bits
    assign sum[0] = p0 ^ cin;
    assign sum[1] = p1 ^ c1;

endmodule