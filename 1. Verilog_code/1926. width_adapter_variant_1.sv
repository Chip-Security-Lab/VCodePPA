//SystemVerilog
module width_adapter #(parameter IN_DW=32, OUT_DW=16) (
    input  wire [IN_DW-1:0] data_in,
    input  wire             sign_extend,
    output wire [OUT_DW-1:0] data_out
);
    localparam RATIO = IN_DW / OUT_DW;

    wire upper_bits_nonzero;
    wire need_sign_extension;
    wire [OUT_DW-1:0] lower_bits;
    wire [OUT_DW-1:0] sign_extension_bits;
    reg  [OUT_DW-1:0] data_out_reg;

    assign upper_bits_nonzero = |data_in[IN_DW-1:OUT_DW];
    assign need_sign_extension = upper_bits_nonzero & sign_extend;
    assign lower_bits = data_in[OUT_DW-1:0];

    // Use LUT-based 8-bit subtractor for sign extension calculation
    wire [7:0] lut_sub_a;
    wire [7:0] lut_sub_b;
    wire [7:0] lut_sub_result;

    assign lut_sub_a = {8{data_in[IN_DW-1]}};
    assign lut_sub_b = 8'b0;

    lut8_subtractor u_lut8_subtractor (
        .a(lut_sub_a),
        .b(lut_sub_b),
        .result(lut_sub_result)
    );

    assign sign_extension_bits = { {(OUT_DW-8){lut_sub_result[7]}}, lut_sub_result };

    always @* begin
        if (need_sign_extension) begin
            data_out_reg = sign_extension_bits | lower_bits;
        end else begin
            data_out_reg = lower_bits;
        end
    end

    assign data_out = data_out_reg;

endmodule

// 8-bit subtractor implemented with LUT (lookup table)
module lut8_subtractor (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output reg  [7:0] result
);
    reg [7:0] lut [0:65535];
    initial begin : generate_lut
        integer i;
        for (i = 0; i < 65536; i = i + 1) begin
            lut[i] = (i[15:8]) - (i[7:0]);
        end
    end

    always @* begin
        result = lut[{a, b}];
    end
endmodule