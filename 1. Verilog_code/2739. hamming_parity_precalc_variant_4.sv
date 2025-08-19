//SystemVerilog
module hamming_parity_precalc(
    input clk,
    input [3:0] data,
    input valid,
    output ready,
    output reg [6:0] code,
    output reg code_valid
);
    reg p1, p2, p4;
    reg processing;
    
    // Ready signal generation - ready when not processing
    assign ready = !processing;
    
    always @(posedge clk) begin
        if (valid && ready) begin
            // Start processing when valid data arrives and we're ready
            processing <= 1'b1;
            
            // Pre-calculate parity bits
            p1 <= data[0] ^ data[1] ^ data[3];
            p2 <= data[0] ^ data[2] ^ data[3];
            p4 <= data[1] ^ data[2] ^ data[3];
        end else if (processing) begin
            // Complete processing in the next cycle
            processing <= 1'b0;
            
            // Assemble code word
            code <= {data[3:1], p4, data[0], p2, p1};
            code_valid <= 1'b1;
        end else begin
            code_valid <= 1'b0;
        end
    end
endmodule