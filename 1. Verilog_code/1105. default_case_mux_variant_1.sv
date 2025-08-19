//SystemVerilog
module default_case_mux (
    input wire [2:0] channel_sel, // Channel selector
    input wire [15:0] ch0, 
    input wire [15:0] ch1, 
    input wire [15:0] ch2, 
    input wire [15:0] ch3, 
    input wire [15:0] ch4, // Channel data
    output reg [15:0] selected    // Selected output
);
    wire [15:0] mul_a, mul_b;
    wire [31:0] bw_product;

    // Example: For demonstration, always multiply ch0 and ch1 using Baugh-Wooley
    // You can change the inputs to the multiplier as needed for your design
    assign mul_a = ch0;
    assign mul_b = ch1;

    baugh_wooley_mult_16x16 bw_mul_inst (
        .a(mul_a),
        .b(mul_b),
        .product(bw_product)
    );

    always @(*) begin
        case (channel_sel)
            3'b000: selected = ch0;
            3'b001: selected = ch1;
            3'b010: selected = ch2;
            3'b011: selected = ch3;
            3'b100: selected = ch4;
            3'b101: selected = bw_product[15:0]; // Example: output LSB of multiplier
            3'b110: selected = bw_product[31:16]; // Example: output MSB of multiplier
            default: selected = 16'h0000;
        endcase
    end
endmodule

module baugh_wooley_mult_16x16(
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [31:0] product
);
    wire [15:0] a_int;
    wire [15:0] b_int;
    wire [31:0] partial[0:15];
    wire [31:0] sum[0:15];
    wire [31:0] carry[0:15];

    assign a_int = a;
    assign b_int = b;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin: gen_partial
            assign partial[i] = {{16{(a_int[15] & b_int[i])}}, (a_int[14:0] & {15{b_int[i]}}), 1'b0} ^
                                ({32{a_int[15] & b_int[i]}} & (32'hFFFF8000 << i));
            if (i == 0) begin
                assign sum[i] = partial[i];
                assign carry[i] = 32'b0;
            end else begin
                assign {carry[i], sum[i]} = sum[i-1] + (partial[i] << i);
            end
        end
    endgenerate

    assign product = sum[15];

endmodule