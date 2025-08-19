module lfsr_4bit (
    input clk, rst_n,
    output [3:0] pseudo_random
);
    reg [3:0] lfsr;
    wire feedback;
    
    assign feedback = lfsr[1] ^ lfsr[3];  // Polynomial: x^4 + x^2 + 1
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr <= 4'b0001;  // Non-zero seed value
        else
            lfsr <= {lfsr[2:0], feedback};
    end
    
    assign pseudo_random = lfsr;
endmodule