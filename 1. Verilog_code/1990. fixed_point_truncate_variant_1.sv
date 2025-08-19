//SystemVerilog
module fixed_point_truncate #(parameter IN_WIDTH=16, OUT_WIDTH=8)(
    input wire [IN_WIDTH-1:0] in_data,
    output reg [OUT_WIDTH-1:0] out_data,
    output reg overflow
);
    wire sign_bit = in_data[IN_WIDTH-1];

    wire [IN_WIDTH-OUT_WIDTH:0] trunc_high_bits;
    wire [IN_WIDTH-OUT_WIDTH:0] trunc_high_bits_inv;
    wire [IN_WIDTH-OUT_WIDTH:0] subtractor_result;
    wire subtractor_carry_out;

    assign trunc_high_bits = in_data[IN_WIDTH-1:OUT_WIDTH-1];
    assign trunc_high_bits_inv = sign_bit ? ~trunc_high_bits : trunc_high_bits;
    assign {subtractor_carry_out, subtractor_result} = 
        {1'b0, trunc_high_bits_inv} + {{(IN_WIDTH-OUT_WIDTH){1'b0}}, sign_bit};

    always @* begin
        if (OUT_WIDTH >= IN_WIDTH) begin
            out_data = {{(OUT_WIDTH-IN_WIDTH){sign_bit}}, in_data};
            overflow = 1'b0;
        end else if (!sign_bit && !(OUT_WIDTH >= IN_WIDTH)) begin
            out_data = in_data[OUT_WIDTH-1:0];
            overflow = |trunc_high_bits[IN_WIDTH-OUT_WIDTH-1:0];
        end else if (sign_bit && !(OUT_WIDTH >= IN_WIDTH)) begin
            out_data = in_data[OUT_WIDTH-1:0];
            overflow = |subtractor_result;
        end else begin
            out_data = {OUT_WIDTH{1'bx}};
            overflow = 1'bx;
        end
    end
endmodule