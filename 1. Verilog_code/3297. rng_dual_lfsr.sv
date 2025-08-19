module rng_dual_lfsr_17(
    input            clk,
    input            rst,
    output reg [7:0] rnd
);
    reg [7:0] sA = 8'hF3, sB = 8'h0D;
    wire fbA = sA[7] ^ sA[5], fbB = sB[6] ^ sB[0];
    always @(posedge clk) begin
        if(rst) begin
            sA <= 8'hF3; sB <= 8'h0D;
        end else begin
            sA <= {sA[6:0], fbB}; 
            sB <= {sB[6:0], fbA};
            rnd <= sA ^ sB;
        end
    end
endmodule