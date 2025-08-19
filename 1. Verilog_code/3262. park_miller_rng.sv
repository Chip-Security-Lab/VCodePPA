module park_miller_rng (
    input wire clk,
    input wire rst,
    output reg [31:0] rand_val
);
    // Park-Miller constants
    parameter A = 16807;
    parameter M = 32'h7FFFFFFF; // 2^31 - 1
    
    reg [31:0] temp;
    
    always @(posedge clk) begin
        if (rst)
            rand_val <= 32'd1;
        else begin
            temp = A * (rand_val % 127773);
            temp = temp - (M / 127773) * (rand_val / 127773);
            if (temp <= 0)
                rand_val <= temp + M;
            else
                rand_val <= temp;
        end
    end
endmodule