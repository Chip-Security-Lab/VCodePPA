module lfsr_counter (
    input wire clk, rst,
    output reg [7:0] lfsr
);
    wire feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];
    
    always @(posedge clk) begin
        if (rst)
            lfsr <= 8'h01;  // Non-zero seed value
        else
            lfsr <= {lfsr[6:0], feedback};
    end
endmodule