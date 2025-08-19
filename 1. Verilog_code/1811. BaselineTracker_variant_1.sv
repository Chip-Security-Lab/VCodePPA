//SystemVerilog
module BaselineTracker #(parameter W=8, TC=8'h10) (
    input clk,
    input [W-1:0] din,
    output [W-1:0] dout
);
    reg [W-1:0] baseline;
    wire [W-1:0] diff;
    
    // Conditional sum subtractor implementation
    ConditionalSumSubtractor #(.WIDTH(W)) subtractor (
        .a(din),
        .b(baseline),
        .diff(diff)
    );
    
    always @(posedge clk) begin
        baseline <= (din > baseline) ? baseline + TC : baseline - TC;
    end
    
    assign dout = diff;
endmodule

module ConditionalSumSubtractor #(parameter WIDTH=8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff
);
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] half_diff_0, half_diff_1;
    wire [WIDTH/2:0] group_borrow;
    
    assign borrow[0] = 1'b0;
    
    // First level: 1-bit subtractors
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: bit_sub
            // Generate half-difference with borrow-in = 0
            assign half_diff_0[i] = a[i] ^ b[i];
            
            // Generate half-difference with borrow-in = 1
            assign half_diff_1[i] = a[i] ^ b[i] ^ 1'b1;
            
            // Generate borrow-out for each bit
            assign borrow[i+1] = (~a[i] & b[i]) | ((~a[i] | b[i]) & borrow[i]);
        end
    endgenerate
    
    // Second level: group-based conditional selection
    assign group_borrow[0] = 1'b0;
    
    generate
        for (i = 0; i < WIDTH; i = i + 2) begin: group_select
            if (i+1 < WIDTH) begin
                // For each group of 2 bits
                wire [1:0] group_diff_0, group_diff_1;
                
                // Differences assuming group borrow-in = 0
                assign group_diff_0[0] = half_diff_0[i];
                assign group_diff_0[1] = (borrow[i+1] & half_diff_1[i+1]) | (~borrow[i+1] & half_diff_0[i+1]);
                
                // Differences assuming group borrow-in = 1
                assign group_diff_1[0] = half_diff_1[i];
                assign group_diff_1[1] = ((borrow[i+1] | 1'b1) & half_diff_1[i+1]) | (~(borrow[i+1] | 1'b1) & half_diff_0[i+1]);
                
                // Select the appropriate difference based on group borrow-in
                assign diff[i] = group_borrow[i/2] ? group_diff_1[0] : group_diff_0[0];
                assign diff[i+1] = group_borrow[i/2] ? group_diff_1[1] : group_diff_0[1];
                
                // Generate group borrow-out
                assign group_borrow[i/2+1] = (group_borrow[i/2] & borrow[i+2]) | 
                                             (~group_borrow[i/2] & borrow[i+2]);
            end else begin
                // Handle odd WIDTH case
                assign diff[i] = group_borrow[i/2] ? half_diff_1[i] : half_diff_0[i];
            end
        end
    endgenerate
endmodule