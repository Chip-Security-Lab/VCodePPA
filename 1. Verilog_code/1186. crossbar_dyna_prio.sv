module crossbar_dyna_prio #(N=4, DW=8) (
    input clk,
    input [N-1:0][3:0] prio,
    input [N-1:0][DW-1:0] din,
    output reg [N-1:0][DW-1:0] dout
);
    reg [3:0] curr_prio[0:N-1];
    integer i;
    
    always @(posedge clk) begin
        for (i = 0; i < N; i = i + 1) begin
            curr_prio[i] <= prio[i];
            
            // Ensure priority value is within valid range
            if (prio[i] < N) begin
                dout[i] <= din[prio[i]];
            end else begin
                dout[i] <= {DW{1'b0}};  // Default to zero if priority is invalid
            end
        end
    end
endmodule