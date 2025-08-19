module sync_majority_filter #(
    parameter WINDOW = 5,
    parameter W = WINDOW / 2 + 1  // Majority threshold
)(
    input clk, rst_n,
    input data_in,
    output reg data_out
);
    reg [WINDOW-1:0] shift_reg;
    reg [2:0] one_count;  // Count of '1's (assumes WINDOW ≤ 7)
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 0;
            one_count <= 0;
            data_out <= 0;
        end else begin
            // Update one count based on bits entering/leaving window
            one_count <= one_count + data_in - shift_reg[WINDOW-1];
            
            // Shift in new data
            shift_reg <= {shift_reg[WINDOW-2:0], data_in};
            
            // Majority decision
            data_out <= (one_count >= W) ? 1'b1 : 1'b0;
        end
    end
endmodule