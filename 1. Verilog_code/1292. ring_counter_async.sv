module ring_counter_async (
    input clk, rst_n, en,
    output reg [3:0] ring_pattern
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ring_pattern <= 4'b0001; // Initialize to a one-hot pattern
    else if (en)
        ring_pattern <= {ring_pattern[2:0], ring_pattern[3]}; // Shift left
    else
        ring_pattern <= 4'b0000; // When enable is low, output all zeros
end
endmodule