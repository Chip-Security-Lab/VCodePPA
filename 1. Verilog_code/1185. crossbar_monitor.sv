module crossbar_monitor #(DW=8, N=4) (
    input clk,
    input [N-1:0][DW-1:0] din,
    output reg [N-1:0][DW-1:0] dout,
    output reg [31:0] traffic_count
);
    integer i;
    reg [31:0] next_traffic_count;
    
    always @(posedge clk) begin
        next_traffic_count = traffic_count;
        
        for (i = 0; i < N; i = i + 1) begin
            // Connect inputs to corresponding outputs in reverse order
            dout[i] <= din[N-1-i];  // Instead of ~i, use N-1-i to reverse connections
            
            // Count traffic based on non-zero inputs
            if (|din[i]) begin
                next_traffic_count = next_traffic_count + 1;
            end
        end
        
        traffic_count <= next_traffic_count;
    end
    
    // Initialize traffic_count to 0
    initial begin
        traffic_count = 0;
    end
endmodule