//SystemVerilog
module bin2bcd #(parameter WIDTH = 8) (
    input wire clk,
    input wire load,
    input wire [WIDTH-1:0] bin_in,
    output reg [11:0] bcd_out,  // 3 BCD digits
    output reg ready
);
    reg [WIDTH-1:0] bin_reg;
    reg [3:0] state;

    wire [3:0] digit0_new;
    wire [3:0] digit1_new;
    wire [3:0] digit2_new;

    reg [3:0] digit0;
    reg [3:0] digit1;
    reg [3:0] digit2;

    wire [3:0] digit0_sum, digit1_sum, digit2_sum;

    // Brent-Kung 4-bit adders for each digit
    brent_kung_adder_4bit bka0 (
        .a(digit0),
        .b(4'd3),
        .sum(digit0_sum)
    );
    brent_kung_adder_4bit bka1 (
        .a(digit1),
        .b(4'd3),
        .sum(digit1_sum)
    );
    brent_kung_adder_4bit bka2 (
        .a(digit2),
        .b(4'd3),
        .sum(digit2_sum)
    );

    always @(posedge clk) begin
        if (load) begin
            bin_reg <= bin_in;
            bcd_out <= 12'b0;
            digit0 <= 4'd0;
            digit1 <= 4'd0;
            digit2 <= 4'd0;
            state <= 4'd0;
            ready <= 1'b0;
        end else if (!ready) begin
            if (state < WIDTH) begin
                // left shift BCD and insert new bit
                {digit2, digit1, digit0} <= {digit2[2:0], digit1, digit0, bin_reg[WIDTH-1]};
                bin_reg <= {bin_reg[WIDTH-2:0], 1'b0};

                // Add 3 to digits > 4 using Brent-Kung adder
                if (digit0 > 4) digit0 <= digit0_sum;
                if (digit1 > 4) digit1 <= digit1_sum;
                if (digit2 > 4) digit2 <= digit2_sum;

                state <= state + 1;
            end else begin
                bcd_out <= {digit2, digit1, digit0};
                ready <= 1'b1;
            end
        end
    end
endmodule

module brent_kung_adder_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [3:0] sum
);
    wire [3:0] g, p;
    wire [3:0] c;

    // Generate and propagate
    assign g = a & b;
    assign p = a ^ b;

    // Brent-Kung prefix computation
    wire g0_1, p0_1, g2_3, p2_3;
    wire g0_3, p0_3;

    // Level 1
    assign g0_1 = g[1] | (p[1] & g[0]);
    assign p0_1 = p[1] & p[0];
    assign g2_3 = g[3] | (p[3] & g[2]);
    assign p2_3 = p[3] & p[2];

    // Level 2
    assign g0_3 = g2_3 | (p2_3 & g0_1);
    assign p0_3 = p2_3 & p0_1;

    // Carries
    assign c[0] = 1'b0;
    assign c[1] = g[0];
    assign c[2] = g0_1;
    assign c[3] = g0_3;

    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
endmodule