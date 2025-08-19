module counting_ring_counter(
    input wire clock,
    input wire reset,
    output reg [3:0] ring_out,
    output reg [1:0] position // Position of the '1' bit
);
    always @(posedge clock) begin
        if (reset) begin
            ring_out <= 4'b0001;
            position <= 2'b00;
        end
        else begin
            ring_out <= {ring_out[2:0], ring_out[3]};
            position <= (position == 2'b11) ? 2'b00 : position + 1;
        end
    end
endmodule