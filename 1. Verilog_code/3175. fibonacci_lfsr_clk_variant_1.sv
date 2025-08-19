//SystemVerilog
module fibonacci_lfsr_clk(
    input clk,
    input rst,
    input ready,          // Ready signal from receiver
    output reg valid,     // Valid signal to indicate output is valid
    output reg [3:0] data // 4-bit data output as specified
);
    reg [4:0] lfsr;
    wire feedback = lfsr[4] ^ lfsr[2];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr <= 5'h1F;     // Non-zero initial value
            valid <= 1'b0;     // Start with valid low
            data <= 4'b0000;   // Initialize data
        end else begin
            lfsr <= {lfsr[3:0], feedback};
            
            // Set valid high to indicate new data is available
            valid <= 1'b1;
            
            // When handshake occurs (valid & ready), prepare new data
            if (valid && ready) begin
                data <= lfsr[4:1];  // Output 4 bits from the LFSR
            end
        end
    end
endmodule