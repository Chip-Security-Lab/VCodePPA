//SystemVerilog
module uniform_rng (
    input wire clk_i,
    input wire rst_i,
    input wire en_i,
    output reg [15:0] random_o
);
    reg [31:0] x_reg, y_reg, z_reg, w_reg;

    // First-stage buffer for x
    reg [31:0] x_buf1;
    // Second-stage buffer for x
    reg [31:0] x_buf2;

    // Buffer for x used in w assignment to balance timing
    reg [31:0] x_w_buf;

    always @(posedge clk_i) begin
        if (rst_i) begin
            x_reg    <= 32'h12345678;
            y_reg    <= 32'h9ABCDEF0;
            z_reg    <= 32'h13579BDF;
            w_reg    <= 32'h2468ACE0;
            x_buf1   <= 32'h12345678;
            x_buf2   <= 32'h12345678;
            x_w_buf  <= 32'h12345678;
            random_o <= 16'h0;
        end else if (en_i) begin
            // Stage 1: x XOR and shift
            x_buf1 <= x_reg ^ (x_reg << 11);
            // Stage 2: x further XOR and shift
            x_buf2 <= x_buf1 ^ (x_buf1 >> 8);
            // Stage 3: x final XOR with y
            x_reg  <= x_buf2 ^ (y_reg ^ (y_reg >> 19));

            // Buffer x for w assignment to balance load
            x_w_buf <= x_reg;

            // Rotate values
            y_reg <= z_reg;
            z_reg <= w_reg;
            w_reg <= x_w_buf;

            random_o <= w_reg[15:0];
        end
    end
endmodule