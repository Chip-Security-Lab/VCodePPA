module preset_ring_counter(
    input wire clk,
    input wire rst,
    input wire preset,
    output reg [3:0] q
);
    always @(posedge clk) begin
        if (rst)
            q <= 4'b0001;
        else if (preset)
            q <= 4'b1000; // Preset to a specific value
        else
            q <= {q[2:0], q[3]};
    end
endmodule