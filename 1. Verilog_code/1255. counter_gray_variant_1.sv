//SystemVerilog
module counter_gray #(parameter BITS=4) (
    input clk, rst_n, en,
    output [BITS-1:0] gray
);
    reg [BITS-1:0] bin;
    reg [BITS-1:0] bin_buf1, bin_buf2;
    
    // Register buffering for high fanout signal 'bin'
    always @(posedge clk) begin
        bin_buf1 <= bin;
        bin_buf2 <= bin;
    end
    
    // Gray code conversion using buffered versions of bin
    assign gray = bin_buf1 ^ (bin_buf2 >> 1);
    
    // Control logic using case statement structure
    always @(posedge clk) begin
        case ({rst_n, en})
            2'b00: bin <= 0;       // Reset active (rst_n=0), en=0
            2'b01: bin <= 0;       // Reset active (rst_n=0), en=1
            2'b10: bin <= bin;     // No reset, but enable is inactive
            2'b11: bin <= bin + 1; // No reset, enable active, increment counter
            default: bin <= bin;   // For completeness
        endcase
    end
endmodule