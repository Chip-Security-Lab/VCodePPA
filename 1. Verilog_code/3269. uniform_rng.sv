module uniform_rng (
    input wire clk_i,
    input wire rst_i,
    input wire en_i,
    output reg [15:0] random_o
);
    reg [31:0] x, y, z, w;
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            x <= 32'h12345678;
            y <= 32'h9ABCDEF0;
            z <= 32'h13579BDF;
            w <= 32'h2468ACE0;
            random_o <= 16'h0;
        end else if (en_i) begin
            // XORshift algorithm
            x <= x ^ (x << 11);
            x <= x ^ (x >> 8);
            x <= x ^ (y ^ (y >> 19));
            
            // Rotate values
            y <= z;
            z <= w;
            w <= x;
            
            random_o <= w[15:0];
        end
    end
endmodule