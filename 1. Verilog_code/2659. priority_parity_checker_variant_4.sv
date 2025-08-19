//SystemVerilog
module priority_parity_checker (
    input [15:0] data,
    output reg [3:0] parity,
    output reg error
);
    // Direct calculation of byte parity
    wire byte_parity = ^data[7:0] ^ ^data[15:8];
    
    // Optimize isolating lowest set bit
    wire [7:0] low_byte = data[7:0];
    wire [7:0] lowest_bit = low_byte & (~low_byte + 1'b1);
    
    always @(*) begin
        // Default assignments
        parity = 4'h0;
        error = 1'b0;
        
        // Simplified condition check
        if (byte_parity && |low_byte) begin
            parity = lowest_bit[3:0];
            error = 1'b1;
        end
    end
endmodule