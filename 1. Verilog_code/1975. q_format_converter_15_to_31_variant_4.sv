//SystemVerilog
module q_format_converter_15_to_31(
    input wire [15:0] q15_in,
    output reg [31:0] q31_out
);
    wire sign_bit;
    wire [14:0] magnitude_bits;
    wire [31:0] extended_magnitude;
    wire [31:0] shifted_magnitude;
    wire [31:0] q31_temp;

    assign sign_bit = q15_in[15];
    assign magnitude_bits = q15_in[14:0];

    // 将magnitude_bits左移16位，最高位补0，得到32位
    assign extended_magnitude = {17'b0, magnitude_bits};
    assign shifted_magnitude = han_carlson_adder_32(extended_magnitude, 32'b0);

    // 设置符号位
    assign q31_temp = {sign_bit, shifted_magnitude[30:0]};

    always @* begin
        q31_out = q31_temp;
    end

    // Han-Carlson加法器32位
    function [31:0] han_carlson_adder_32;
        input [31:0] a;
        input [31:0] b;
        reg [31:0] g [0:5];
        reg [31:0] p [0:5];
        reg [31:0] c;
        integer i;
        begin
            // Stage 0: Generate and Propagate
            g[0] = a & b;
            p[0] = a ^ b;

            // Stage 1: 1-bit group
            for (i = 0; i < 32; i = i + 1)
                if (i == 0) begin
                    g[1][i] = g[0][i];
                    p[1][i] = p[0][i];
                end else begin
                    g[1][i] = g[0][i] | (p[0][i] & g[0][i-1]);
                    p[1][i] = p[0][i] & p[0][i-1];
                end

            // Stage 2: 2-bit group
            for (i = 0; i < 32; i = i + 1)
                if (i < 2) begin
                    g[2][i] = g[1][i];
                    p[2][i] = p[1][i];
                end else begin
                    g[2][i] = g[1][i] | (p[1][i] & g[1][i-2]);
                    p[2][i] = p[1][i] & p[1][i-2];
                end

            // Stage 3: 4-bit group
            for (i = 0; i < 32; i = i + 1)
                if (i < 4) begin
                    g[3][i] = g[2][i];
                    p[3][i] = p[2][i];
                end else begin
                    g[3][i] = g[2][i] | (p[2][i] & g[2][i-4]);
                    p[3][i] = p[2][i] & p[2][i-4];
                end

            // Stage 4: 8-bit group
            for (i = 0; i < 32; i = i + 1)
                if (i < 8) begin
                    g[4][i] = g[3][i];
                    p[4][i] = p[3][i];
                end else begin
                    g[4][i] = g[3][i] | (p[3][i] & g[3][i-8]);
                    p[4][i] = p[3][i] & p[3][i-8];
                end

            // Stage 5: 16-bit group
            for (i = 0; i < 32; i = i + 1)
                if (i < 16) begin
                    g[5][i] = g[4][i];
                    p[5][i] = p[4][i];
                end else begin
                    g[5][i] = g[4][i] | (p[4][i] & g[4][i-16]);
                    p[5][i] = p[4][i] & p[4][i-16];
                end

            // Carry
            c[0] = 1'b0;
            for (i = 1; i < 32; i = i + 1) begin
                c[i] = g[5][i-1] | (p[5][i-1] & c[i-1]);
            end

            // Sum
            for (i = 0; i < 32; i = i + 1)
                han_carlson_adder_32[i] = p[0][i] ^ c[i];
        end
    endfunction

endmodule