module hamming_parity_precalc(
    input clk, en,
    input [3:0] data,
    output reg [6:0] code
);
    reg p1, p2, p4;
    
    always @(posedge clk) begin
        if (en) begin
            // Pre-calculate parity bits
            p1 <= data[0] ^ data[1] ^ data[3];
            p2 <= data[0] ^ data[2] ^ data[3];
            p4 <= data[1] ^ data[2] ^ data[3];
            
            // Assemble code word
            code <= {data[3:1], p4, data[0], p2, p1};
        end
    end
endmodule