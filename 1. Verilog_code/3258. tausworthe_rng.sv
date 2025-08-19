module tausworthe_rng (
    input clk_in,
    input rst_in,
    output [31:0] rnd_out
);
    reg [31:0] s1, s2, s3;
    wire [31:0] b1, b2, b3;
    
    assign b1 = ((s1 << 13) ^ s1) >> 19;
    assign b2 = ((s2 << 2) ^ s2) >> 25;
    assign b3 = ((s3 << 3) ^ s3) >> 11;
    
    always @(posedge clk_in) begin
        if (rst_in) begin
            s1 <= 32'h1;
            s2 <= 32'h2;
            s3 <= 32'h4;
        end else begin
            s1 <= (s1 & 32'hFFFFFFFE) ^ b1;
            s2 <= (s2 & 32'hFFFFFFF8) ^ b2;
            s3 <= (s3 & 32'hFFFFFFF0) ^ b3;
        end
    end
    
    assign rnd_out = s1 ^ s2 ^ s3;
endmodule