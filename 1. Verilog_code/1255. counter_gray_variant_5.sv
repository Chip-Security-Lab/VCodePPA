//SystemVerilog
//IEEE 1364-2005 Verilog
module counter_gray #(parameter BITS=4) (
    input clk, rst_n, en,
    output reg [BITS-1:0] gray
);
    reg [BITS-1:0] bin;
    reg [BITS-1:0] next_bin;
    wire [BITS-1:0] next_gray;
    
    // Pre-compute next binary value
    always @(*) begin
        if (en)
            next_bin = bin + 1;
        else
            next_bin = bin;
    end
    
    // Compute gray code directly from binary
    assign next_gray = next_bin ^ (next_bin >> 1);
    
    // Register updates
    always @(posedge clk) begin
        if (!rst_n) begin
            bin <= 0;
            gray <= 0;
        end
        else begin
            bin <= next_bin;
            gray <= next_gray;
        end
    end
endmodule