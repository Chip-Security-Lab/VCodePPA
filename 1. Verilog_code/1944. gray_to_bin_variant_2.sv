//SystemVerilog
module gray_to_bin #(
    parameter DATA_W = 8
)(
    input  [DATA_W-1:0] gray_code,
    output [DATA_W-1:0] binary
);
    integer idx_i;
    reg [DATA_W-1:0] bin_temp;
    wire [DATA_W-1:0] subtractor_b_input;
    wire [DATA_W-1:0] subtractor_b_inverted;
    wire [DATA_W-1:0] subtractor_sum;

    // Generate one_vec = 1 for subtraction
    assign subtractor_b_input = { {(DATA_W-1){1'b0}}, 1'b1 };

    // Two's complement subtraction: a - b = a + (~b + 1)
    assign subtractor_b_inverted = ~subtractor_b_input;
    assign subtractor_sum = bin_temp + subtractor_b_inverted + 1'b1;

    always @(*) begin
        bin_temp[DATA_W-1] = gray_code[DATA_W-1];
        for (idx_i = DATA_W-2; idx_i >= 0; idx_i = idx_i - 1) begin
            bin_temp[idx_i] = bin_temp[idx_i+1] ^ gray_code[idx_i];
        end
    end

    assign binary = subtractor_sum;

endmodule