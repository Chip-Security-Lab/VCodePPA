module async_reset_ring_counter(
    input wire clk,
    input wire rst_n, // Active-low reset
    output reg [3:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 4'b0001; // Reset to initial state
        else
            q <= {q[2:0], q[3]}; // Circular shift
    end
endmodule