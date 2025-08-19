module ring_counter (
    input wire clock, reset,
    output reg [7:0] ring
);
    always @(posedge clock) begin
        if (reset)
            ring <= 8'b10000000;
        else
            ring <= {ring[0], ring[7:1]};
    end
endmodule
