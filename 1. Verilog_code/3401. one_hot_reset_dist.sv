module one_hot_reset_dist(
    input wire clk,
    input wire [1:0] reset_select,
    input wire reset_in,
    output reg [3:0] reset_out
);
    always @(posedge clk) begin
        reset_out <= 4'b0000;
        if (reset_in)
            reset_out[reset_select] <= 1'b1;
    end
endmodule