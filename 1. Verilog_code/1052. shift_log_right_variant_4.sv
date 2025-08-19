//SystemVerilog
module shift_log_right #(parameter WIDTH=8, SHIFT=2) (
    input  [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);

wire [WIDTH-1:0] shifted_data;
wire [WIDTH-1:0] subtractor_result;

// Conditional sum-subtract subtractor (8-bit)
cond_sum_subtractor_8bit u_cond_sum_subtractor (
    .minuend(data_in),
    .subtrahend({{(WIDTH-SHIFT){1'b0}}, SHIFT}),
    .difference(subtractor_result)
);

assign shifted_data = subtractor_result;
assign data_out = shifted_data;

endmodule

// 8-bit Conditional Sum Subtractor
module cond_sum_subtractor_8bit (
    input  [7:0] minuend,
    input  [7:0] subtrahend,
    output [7:0] difference
);

wire [7:0] subtrahend_complement;
wire       carry_in;
wire [7:0] sum0, sum1;
wire [7:0] carry0, carry1;
wire [7:0] select;
wire [7:0] carry_chain;

assign subtrahend_complement = ~subtrahend;
assign carry_in = 1'b1; // For subtraction (minuend - subtrahend): add 2's complement

// Conditional sum for each bit
genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin : gen_cond_sum
        if (i == 0) begin
            assign sum0[i]   = minuend[i] ^ subtrahend_complement[i] ^ 1'b0;
            assign carry0[i] = (minuend[i] & subtrahend_complement[i]) | (minuend[i] & 1'b0) | (subtrahend_complement[i] & 1'b0);

            assign sum1[i]   = minuend[i] ^ subtrahend_complement[i] ^ 1'b1;
            assign carry1[i] = (minuend[i] & subtrahend_complement[i]) | (minuend[i] & 1'b1) | (subtrahend_complement[i] & 1'b1);

            assign select[i] = carry_in;
            assign difference[i] = select[i] ? sum1[i] : sum0[i];
            assign carry_chain[i] = select[i] ? carry1[i] : carry0[i];
        end else begin
            assign sum0[i]   = minuend[i] ^ subtrahend_complement[i] ^ 1'b0;
            assign carry0[i] = (minuend[i] & subtrahend_complement[i]) | (minuend[i] & 1'b0) | (subtrahend_complement[i] & 1'b0);

            assign sum1[i]   = minuend[i] ^ subtrahend_complement[i] ^ 1'b1;
            assign carry1[i] = (minuend[i] & subtrahend_complement[i]) | (minuend[i] & 1'b1) | (subtrahend_complement[i] & 1'b1);

            assign select[i] = carry_chain[i-1];
            assign difference[i] = select[i] ? sum1[i] : sum0[i];
            assign carry_chain[i] = select[i] ? carry1[i] : carry0[i];
        end
    end
endgenerate

endmodule