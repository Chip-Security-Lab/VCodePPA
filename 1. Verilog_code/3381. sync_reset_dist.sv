module sync_reset_dist(
    input wire clk,
    input wire rst_in,
    output reg [7:0] rst_out
);
    always @(posedge clk) begin
        if (rst_in)
            rst_out <= 8'hFF;  // All outputs active
        else
            rst_out <= 8'h00;  // All outputs inactive
    end
endmodule