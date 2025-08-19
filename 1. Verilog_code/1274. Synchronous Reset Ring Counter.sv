module sync_reset_ring_counter(
    input wire clock,
    input wire reset, // Active-high reset
    output reg [3:0] out
);
    always @(posedge clock) begin
        if (reset)
            out <= 4'b0001; // Initial state
        else
            out <= {out[2:0], out[3]}; // Rotate
    end
endmodule