//SystemVerilog
module enc_8b10b (
    input  wire [7:0] data_in,
    output reg  [9:0] encoded
);
    wire signed [9:0] mult_result_0;
    wire signed [9:0] mult_result_1;
    wire signed [9:0] signed_const_0;
    wire signed [9:0] signed_const_1;

    assign signed_const_0 = 10'sd1;
    assign signed_const_1 = 10'sd1;

    assign mult_result_0 = signed_const_0 * 10'sd655; // 1001110100 = 0x274, 655
    assign mult_result_1 = signed_const_1 * 10'sd468; // 0111010100 = 0x1D4, 468

    always @* begin
        if (data_in == 8'h00) begin
            encoded = mult_result_0;
        end else if (data_in == 8'h01) begin
            encoded = mult_result_1;
        end else begin
            encoded = 10'b0000000000;
        end
    end
endmodule