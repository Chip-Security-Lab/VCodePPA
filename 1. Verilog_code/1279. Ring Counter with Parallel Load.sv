module loadable_ring_counter(
    input wire clock,
    input wire reset,
    input wire load,
    input wire [3:0] data_in,
    output reg [3:0] ring_out
);
    always @(posedge clock) begin
        if (reset)
            ring_out <= 4'b0001;
        else if (load)
            ring_out <= data_in;
        else
            ring_out <= {ring_out[2:0], ring_out[3]};
    end
endmodule