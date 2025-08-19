module crossbar_tdma #(DW=8, N=4) (
    input clk, 
    input [31:0] global_time,
    input [N-1:0][DW-1:0] din,
    output reg [N-1:0][DW-1:0] dout
);
    wire [1:0] time_slot = global_time[27:26];
    
    integer i;
    always @(posedge clk) begin
        // Reset dout to all zeros
        for (i = 0; i < N; i = i + 1) begin
            dout[i] <= {DW{1'b0}};
        end
        
        // Route input based on current time slot
        if (time_slot < N) begin
            for (i = 0; i < N; i = i + 1) begin
                // Route data from current time slot to all outputs
                dout[i] <= din[time_slot];
            end
        end
    end
endmodule