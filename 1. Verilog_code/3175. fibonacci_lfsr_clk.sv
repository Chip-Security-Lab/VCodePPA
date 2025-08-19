module fibonacci_lfsr_clk(
    input clk,
    input rst,
    output reg lfsr_clk
);
    reg [4:0] lfsr;
    wire feedback = lfsr[4] ^ lfsr[2];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr <= 5'h1F;  // Non-zero initial value
            lfsr_clk <= 1'b0;
        end else begin
            lfsr <= {lfsr[3:0], feedback};
            lfsr_clk <= lfsr[4];
        end
    end
endmodule