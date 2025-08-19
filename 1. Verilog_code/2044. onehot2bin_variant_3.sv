//SystemVerilog
module onehot2bin #(
    parameter OH_WIDTH = 8,
    parameter OUT_WIDTH = 3
)(
    input wire [OH_WIDTH-1:0] onehot_in,
    output reg [OUT_WIDTH-1:0] bin_out
);

    // Internal signals for two's complement subtraction
    reg [OH_WIDTH-1:0] onehot_minus_one;
    reg [OUT_WIDTH-1:0] bin_result;
    integer i;

    always @(*) begin
        // Two's complement subtraction: onehot_in - 1
        onehot_minus_one = onehot_in + (~8'b00000001 + 1'b1);

        // Binary encoding using two's complement subtraction result
        bin_result = {OUT_WIDTH{1'b0}};
        for (i = OH_WIDTH-1; i >= 0; i = i - 1) begin
            if (onehot_in[i]) begin
                // Subtract 1 using two's complement, then get binary index
                bin_result = i[OUT_WIDTH-1:0];
            end
        end

        // Output
        if (onehot_in == 8'b00000001) bin_out = 3'd0;
        else if (onehot_in == 8'b00000010) bin_out = 3'd1;
        else if (onehot_in == 8'b00000100) bin_out = 3'd2;
        else if (onehot_in == 8'b00001000) bin_out = 3'd3;
        else if (onehot_in == 8'b00010000) bin_out = 3'd4;
        else if (onehot_in == 8'b00100000) bin_out = 3'd5;
        else if (onehot_in == 8'b01000000) bin_out = 3'd6;
        else if (onehot_in == 8'b10000000) bin_out = 3'd7;
        else bin_out = {OUT_WIDTH{1'b0}};
    end

endmodule