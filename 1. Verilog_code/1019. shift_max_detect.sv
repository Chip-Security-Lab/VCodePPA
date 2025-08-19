module shift_max_detect #(parameter W=8) (
    input clk,
    input [W-1:0] din,
    output reg [$clog2(W)-1:0] max_shift
);
    reg [W-1:0] data;
    integer i;
    
    always @(posedge clk) begin
        data <= din;
        max_shift <= W-1; // Default to maximum shift if no 1s found
        
        // Use a for loop instead of while loop for better synthesis
        for (i = 0; i < W; i = i + 1) begin
            if (din[i] == 1'b1 && i < max_shift) begin
                max_shift <= i;
            end
        end
    end
endmodule