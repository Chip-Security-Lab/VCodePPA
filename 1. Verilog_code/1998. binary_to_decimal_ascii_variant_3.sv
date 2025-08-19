//SystemVerilog

module binary_to_decimal_ascii_valid_ready #(parameter WIDTH=8)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 binary_in_valid,
    output wire                 binary_in_ready,
    input  wire [WIDTH-1:0]     binary_in,
    output reg                  ascii_out_valid,
    input  wire                 ascii_out_ready,
    output reg  [8*3-1:0]       ascii_out // 最多3位十进制数的ASCII
);
    // Internal registers for handshake and pipelining
    reg [WIDTH-1:0]             binary_in_reg;
    reg                         binary_in_reg_valid;
    wire                        binary_in_handshake;
    wire                        ascii_out_handshake;

    // Internal signals for conversion
    reg [3:0] hundreds, tens, ones;
    wire [WIDTH-1:0] div100_quotient, div10_quotient;
    wire [6:0] mod10_remainder, div10_mod10_remainder;

    // Valid-Ready handshake logic for input
    assign binary_in_ready = !binary_in_reg_valid || (ascii_out_valid && ascii_out_ready);

    assign binary_in_handshake = binary_in_valid && binary_in_ready;
    assign ascii_out_handshake = ascii_out_valid && ascii_out_ready;

    // Latch input on handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_in_reg <= {WIDTH{1'b0}};
            binary_in_reg_valid <= 1'b0;
        end else if (binary_in_handshake) begin
            binary_in_reg <= binary_in;
            binary_in_reg_valid <= 1'b1;
        end else if (ascii_out_handshake) begin
            binary_in_reg_valid <= 1'b0;
        end
    end

    // Division and modulus by constants implemented combinationally
    divider_by_const #(.WIDTH(WIDTH), .DIVISOR(100)) div_by_100 (
        .dividend(binary_in_reg),
        .quotient(div100_quotient),
        .remainder()
    );

    divider_by_const #(.WIDTH(WIDTH), .DIVISOR(10)) div_by_10 (
        .dividend(binary_in_reg),
        .quotient(div10_quotient),
        .remainder(mod10_remainder)
    );

    divider_by_const #(.WIDTH(WIDTH), .DIVISOR(10)) div_by_10_after_100 (
        .dividend(binary_in_reg - (div100_quotient * 100)),
        .quotient(),
        .remainder(div10_mod10_remainder)
    );

    // Pipelined output valid generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ascii_out_valid <= 1'b0;
        end else if (binary_in_reg_valid && !ascii_out_valid) begin
            ascii_out_valid <= 1'b1;
        end else if (ascii_out_handshake) begin
            ascii_out_valid <= 1'b0;
        end
    end

    // Output ascii_out generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ascii_out <= {24{1'b0}};
        end else if (binary_in_reg_valid && (!ascii_out_valid || (ascii_out_valid && ascii_out_ready))) begin
            hundreds = div100_quotient[3:0];
            tens     = div10_quotient[3:0] % 10;
            ones     = mod10_remainder[3:0];

            ascii_out[23:16] <= hundreds ? (8'h30 + hundreds) : 8'h20; // 空格或数字
            ascii_out[15:8]  <= (hundreds || tens) ? (8'h30 + tens) : 8'h20; // 空格或数字
            ascii_out[7:0]   <= 8'h30 + ones; // 始终显示个位数
        end
    end
endmodule

module divider_by_const #(parameter WIDTH=8, parameter DIVISOR=10)(
    input  wire [WIDTH-1:0] dividend,
    output wire [WIDTH-1:0] quotient,
    output wire [WIDTH-1:0] remainder
);
    // Only supports DIVISOR=10 or 100 for this specific use case
    wire [WIDTH-1:0] temp_quotient;
    wire [WIDTH-1:0] temp_remainder;
    assign temp_quotient = (DIVISOR == 10)  ? div_by_10_han_carlson(dividend)  :
                           (DIVISOR == 100) ? div_by_100_han_carlson(dividend) : {WIDTH{1'b0}};
    assign temp_remainder = dividend - temp_quotient * DIVISOR;
    assign quotient = temp_quotient;
    assign remainder = temp_remainder;

    function [WIDTH-1:0] div_by_10_han_carlson;
        input [WIDTH-1:0] value;
        reg [WIDTH-1:0] q;
        begin
            // Approximate division by 10: q = (value * 205) >> 11
            q = (value * 8'd205) >> 11;
            div_by_10_han_carlson = q;
        end
    endfunction

    function [WIDTH-1:0] div_by_100_han_carlson;
        input [WIDTH-1:0] value;
        reg [WIDTH-1:0] q;
        begin
            // Approximate division by 100: q = (value * 41) >> 12
            q = (value * 8'd41) >> 12;
            div_by_100_han_carlson = q;
        end
    endfunction
endmodule

module han_carlson_adder_8bit(
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       cin,
    output wire [7:0] sum,
    output wire       cout
);
    wire [7:0] p, g;
    wire [7:0] c;

    assign p = a ^ b;
    assign g = a & b;

    wire [7:0] g1, p1, g2, p2, g3, p3;
    // Stage 1
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    genvar i;
    generate
        for (i=1; i<8; i=i+1) begin: gen_g1
            assign g1[i] = g[i] | (p[i] & g[i-1]);
            assign p1[i] = p[i] & p[i-1];
        end
    endgenerate
    // Stage 2
    assign g2[0] = g1[0];
    assign g2[1] = g1[1];
    assign p2[0] = p1[0];
    assign p2[1] = p1[1];
    generate
        for (i=2; i<8; i=i+1) begin: gen_g2
            assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
            assign p2[i] = p1[i] & p1[i-2];
        end
    endgenerate
    // Stage 3
    assign g3[0] = g2[0];
    assign g3[1] = g2[1];
    assign g3[2] = g2[2];
    assign g3[3] = g2[3];
    assign p3[0] = p2[0];
    assign p3[1] = p2[1];
    assign p3[2] = p2[2];
    assign p3[3] = p2[3];
    generate
        for (i=4; i<8; i=i+1) begin: gen_g3
            assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
            assign p3[i] = p2[i] & p2[i-4];
        end
    endgenerate

    // Carry computation
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g1[1] | (p1[1] & cin);
    assign c[3] = g2[2] | (p2[2] & cin);
    assign c[4] = g3[3] | (p3[3] & cin);
    assign c[5] = g3[4] | (p3[4] & cin);
    assign c[6] = g3[5] | (p3[5] & cin);
    assign c[7] = g3[6] | (p3[6] & cin);

    assign sum = p ^ c;
    assign cout = g3[7] | (p3[7] & cin);
endmodule