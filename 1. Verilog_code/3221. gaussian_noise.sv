module gaussian_noise(
    input clk,
    input rst,
    output reg [7:0] noise_out
);
    reg [15:0] lfsr1, lfsr2;
    wire fb1 = lfsr1[15] ^ lfsr1[14] ^ lfsr1[12] ^ lfsr1[3];
    wire fb2 = lfsr2[15] ^ lfsr2[13] ^ lfsr2[11] ^ lfsr2[7];
    
    always @(posedge clk) begin
        if (rst) begin
            lfsr1 <= 16'hACE1;
            lfsr2 <= 16'h1234;
            noise_out <= 8'h80;
        end else begin
            lfsr1 <= {lfsr1[14:0], fb1};
            lfsr2 <= {lfsr2[14:0], fb2};
            // Sum of two random values approximates Gaussian
            noise_out <= {1'b0, lfsr1[7:1]} + {1'b0, lfsr2[7:1]};
        end
    end
endmodule