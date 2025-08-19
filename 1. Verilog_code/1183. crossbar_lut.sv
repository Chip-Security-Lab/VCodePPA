module crossbar_lut #(DW=8, N=4, AW=4) ( 
    input clk,
    input [AW-1:0] route_table[0:N-1],  // Fixed array declaration
    input [N-1:0][DW-1:0] din,
    output reg [N-1:0][DW-1:0] dout
);
    integer i;
    
    always @(posedge clk) begin
        // Initialize dout to zeros
        for (i = 0; i < N; i = i + 1) begin
            dout[i] <= {DW{1'b0}};
        end
        
        // Apply routing based on LUT
        for (i = 0; i < N; i = i + 1) begin
            // Ensure route_table index is within valid range
            if (route_table[i] < N) begin
                dout[route_table[i]] <= din[i];
            end
        end
    end
endmodule