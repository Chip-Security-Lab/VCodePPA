//SystemVerilog
module shift_mux_based #(parameter WIDTH=8) (
    input  [WIDTH-1:0] data_in,
    input  [$clog2(WIDTH)-1:0] shift_amt,
    output [WIDTH-1:0] data_out
);

wire [WIDTH-1:0] shift_operand;
wire [$clog2(WIDTH)-1:0] shift_neg_amt;
wire [WIDTH-1:0] shifted_result;
wire [WIDTH-1:0] shift_amt_onehot;
wire [WIDTH-1:0] shift_temp [0:WIDTH-1];

assign shift_neg_amt = (~shift_amt) + 1'b1; // Two's complement for subtraction

// Generate one-hot selection for shifting
genvar i;
generate
    for (i = 0; i < WIDTH; i = i + 1) begin : gen_shift_amt_onehot
        assign shift_amt_onehot[i] = (shift_amt == i);
    end
endgenerate

// Implement shifting using a mux-based structure
generate
    for (i = 0; i < WIDTH; i = i + 1) begin : gen_shift_mux
        assign shift_temp[i] = data_in << i;
    end
endgenerate

assign shifted_result = 
    (shift_amt_onehot[0] ? shift_temp[0] :
    (shift_amt_onehot[1] ? shift_temp[1] :
    (shift_amt_onehot[2] ? shift_temp[2] :
    (shift_amt_onehot[3] ? shift_temp[3] :
    (shift_amt_onehot[4] ? shift_temp[4] :
    (shift_amt_onehot[5] ? shift_temp[5] :
    (shift_amt_onehot[6] ? shift_temp[6] :
    (shift_amt_onehot[7] ? shift_temp[7] : {WIDTH{1'b0}}))))))));

assign data_out = shifted_result;

endmodule