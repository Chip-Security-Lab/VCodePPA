//SystemVerilog
module HysteresisFilter #(parameter W=8, HYST=4) (
    input clk, 
    input [W-1:0] din,
    output reg out
);
    reg [W-1:0] prev;
    
    // Direct comparison signals
    wire greater_than_comb = (din > prev + HYST);
    wire less_than_comb = (din < prev - HYST);
    
    // Registered comparisons
    reg greater_than, less_than;
    
    always @(posedge clk) begin
        // Register the comparison results
        greater_than <= greater_than_comb;
        less_than <= less_than_comb;
        
        // Update output based on registered comparison results using case
        case({greater_than, less_than})
            2'b10: out <= 1'b1;  // greater_than is true
            2'b01: out <= 1'b0;  // less_than is true
            default: out <= out; // Keep previous value
        endcase
        
        // Update previous value
        prev <= din;
    end
endmodule