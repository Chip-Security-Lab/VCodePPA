//SystemVerilog
module adaptive_quant(
    input  wire [31:0] f,
    input  wire [7:0]  bits,
    output reg  [31:0] q
);
    reg  [31:0] scale;
    wire signed [31:0] signed_f;
    wire signed [31:0] signed_scale;
    wire signed [63:0] signed_mult_result;
    reg  [63:0] temp_result;

    assign signed_f = f;
    assign signed_scale = scale;
    assign signed_mult_result = signed_multiply_64(signed_f, signed_scale);

    always @(*) begin
        scale = 32'd1 <<< bits;
        temp_result = signed_mult_result;

        // 溢出检测和处理
        if (f[31] == 1'b0 && temp_result[63:31] != 33'd0) // 正数溢出
            q = 32'h7FFFFFFF;
        else if (f[31] == 1'b1 && temp_result[63:31] != {33{1'b1}}) // 负数溢出
            q = 32'h80000000;
        else
            q = temp_result[31:0];
    end

    function automatic signed [63:0] signed_multiply_64;
        input signed [31:0] a;
        input signed [31:0] b;
        reg   [63:0] a_abs, b_abs;
        reg   [63:0] unsigned_result;
        reg          result_sign;
        begin
            result_sign = a[31] ^ b[31];
            a_abs = a[31] ? (~a + 1'b1) : a;
            b_abs = b[31] ? (~b + 1'b1) : b;
            unsigned_result = booth_mult_32x32(a_abs[31:0], b_abs[31:0]);
            signed_multiply_64 = result_sign ? (~unsigned_result + 1'b1) : unsigned_result;
        end
    endfunction

    function automatic [63:0] booth_mult_32x32;
        input [31:0] x;
        input [31:0] y;
        reg [63:0] multiplicand;
        reg [63:0] product;
        reg [33:0] y_ext;
        integer i;
        begin
            multiplicand = {32'd0, x};
            product = 64'd0;
            y_ext = {y, 2'b00};
            for (i = 0; i < 32; i = i + 1) begin
                case (y_ext[2:0])
                    3'b001, 3'b010: product = brent_kung_adder_64(product, (multiplicand << i));
                    3'b011:         product = brent_kung_adder_64(product, (multiplicand << (i+1)));
                    3'b100:         product = brent_kung_adder_64(product, (~(multiplicand << (i+1)) + 1'b1));
                    3'b101, 3'b110: product = brent_kung_adder_64(product, (~(multiplicand << i) + 1'b1));
                    default:        ;
                endcase
                y_ext = y_ext >> 1;
            end
            booth_mult_32x32 = product;
        end
    endfunction

    function automatic [63:0] brent_kung_adder_64;
        input [63:0] a;
        input [63:0] b;
        reg [63:0] g, p, x;
        reg [63:0] c;
        integer i;

        // Intermediate carries for Brent-Kung tree
        reg [63:0] g1, p1;
        reg [63:0] g2, p2;
        reg [63:0] g3, p3;
        reg [63:0] g4, p4;
        reg [63:0] g5, p5;
        reg [63:0] g6, p6;
        reg [63:0] g7, p7;

        begin
            // Generate and propagate
            g = a & b;
            p = a ^ b;

            // Level 1
            g1 = g;
            p1 = p;
            for (i = 1; i < 64; i = i + 1)
                if (i % 2 == 1) begin
                    g1[i] = g[i] | (p[i] & g[i-1]);
                    p1[i] = p[i] & p[i-1];
                end

            // Level 2
            g2 = g1;
            p2 = p1;
            for (i = 3; i < 64; i = i + 1)
                if (i % 4 == 3) begin
                    g2[i] = g1[i] | (p1[i] & g1[i-2]);
                    p2[i] = p1[i] & p1[i-2];
                end

            // Level 3
            g3 = g2;
            p3 = p2;
            for (i = 7; i < 64; i = i + 1)
                if (i % 8 == 7) begin
                    g3[i] = g2[i] | (p2[i] & g2[i-4]);
                    p3[i] = p2[i] & p2[i-4];
                end

            // Level 4
            g4 = g3;
            p4 = p3;
            for (i = 15; i < 64; i = i + 1)
                if (i % 16 == 15) begin
                    g4[i] = g3[i] | (p3[i] & g3[i-8]);
                    p4[i] = p3[i] & p3[i-8];
                end

            // Level 5
            g5 = g4;
            p5 = p4;
            for (i = 31; i < 64; i = i + 1)
                if (i % 32 == 31) begin
                    g5[i] = g4[i] | (p4[i] & g4[i-16]);
                    p5[i] = p4[i] & p4[i-16];
                end

            // Level 6
            g6 = g5;
            p6 = p5;
            for (i = 63; i < 64; i = i + 1) begin
                g6[i] = g5[i] | (p5[i] & g5[i-32]);
                p6[i] = p5[i] & p5[i-32];
            end

            // Backward carry computation
            c[0] = 1'b0;
            c[1] = g[0] | (p[0] & c[0]);
            c[2] = g1[1] | (p1[1] & c[0]);
            c[3] = g1[2] | (p1[2] & c[1]);
            c[4] = g2[3] | (p2[3] & c[0]);
            c[5] = g1[4] | (p1[4] & c[3]);
            c[6] = g1[5] | (p1[5] & c[4]);
            c[7] = g2[6] | (p2[6] & c[3]);
            c[8] = g3[7] | (p3[7] & c[0]);
            c[9] = g1[8] | (p1[8] & c[7]);
            c[10] = g1[9] | (p1[9] & c[8]);
            c[11] = g2[10] | (p2[10] & c[7]);
            c[12] = g1[11] | (p1[11] & c[10]);
            c[13] = g1[12] | (p1[12] & c[11]);
            c[14] = g2[13] | (p2[13] & c[10]);
            c[15] = g3[14] | (p3[14] & c[7]);
            c[16] = g4[15] | (p4[15] & c[0]);
            for (i = 17; i < 64; i = i + 1) begin
                c[i] = g[i-1] | (p[i-1] & c[i-1]);
            end

            brent_kung_adder_64 = p ^ c;
        end
    endfunction

endmodule