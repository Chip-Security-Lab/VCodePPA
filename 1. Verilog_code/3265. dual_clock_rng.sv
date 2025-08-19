module dual_clock_rng (
    input wire clk_a,
    input wire clk_b,
    input wire rst,
    output wire [31:0] random_out
);
    reg [15:0] lfsr_a;
    reg [15:0] lfsr_b;
    
    always @(posedge clk_a) begin
        if (rst)
            lfsr_a <= 16'hACE1;
        else
            lfsr_a <= {lfsr_a[14:0], lfsr_a[15] ^ lfsr_a[14] ^ lfsr_a[12] ^ lfsr_a[3]};
    end
    
    always @(posedge clk_b) begin
        if (rst)
            lfsr_b <= 16'h1CE2;
        else
            lfsr_b <= {lfsr_b[14:0], lfsr_b[15] ^ lfsr_b[13] ^ lfsr_b[9] ^ lfsr_b[2]};
    end
    
    assign random_out = {lfsr_a, lfsr_b};
endmodule