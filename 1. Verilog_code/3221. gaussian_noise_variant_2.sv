//SystemVerilog
module gaussian_noise(
    input clk,
    input rst,
    output reg [7:0] noise_out
);
    reg [15:0] lfsr1, lfsr2;
    
    wire fb1 = ^{lfsr1[15], lfsr1[14], lfsr1[12], lfsr1[3]};
    wire fb2 = ^{lfsr2[15], lfsr2[13], lfsr2[11], lfsr2[7]};
    
    wire [15:0] next_lfsr1 = {lfsr1[14:0], fb1};
    wire [15:0] next_lfsr2 = {lfsr2[14:0], fb2};
    
    wire [7:0] noise_sum = {1'b0, next_lfsr1[7:1]} + {1'b0, next_lfsr2[7:1]};
    
    always @(posedge clk) begin
        lfsr1 <= rst ? 16'hACE1 : next_lfsr1;
        lfsr2 <= rst ? 16'h1234 : next_lfsr2;
        noise_out <= rst ? 8'h80 : noise_sum;
    end
endmodule