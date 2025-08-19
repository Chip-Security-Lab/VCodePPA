module hybrid_reset_dist(
    input wire clk,
    input wire async_rst,
    input wire sync_rst,
    input wire [3:0] mode_select,
    output reg [3:0] reset_out
);
    always @(posedge clk or posedge async_rst) begin
        if (async_rst)
            reset_out <= 4'b1111;
        else if (sync_rst)
            reset_out <= mode_select & 4'b1111;
        else
            reset_out <= 4'b0000;
    end
endmodule
