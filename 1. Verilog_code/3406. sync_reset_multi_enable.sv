module sync_reset_multi_enable(
    input wire clk,
    input wire reset_in,
    input wire [3:0] enable_conditions,
    output reg [3:0] reset_out
);
    always @(posedge clk) begin
        if (reset_in)
            reset_out <= 4'b1111;
        else begin
            reset_out[0] <= enable_conditions[0] ? 1'b0 : reset_out[0];
            reset_out[1] <= enable_conditions[1] ? 1'b0 : reset_out[1];
            reset_out[2] <= enable_conditions[2] ? 1'b0 : reset_out[2];
            reset_out[3] <= enable_conditions[3] ? 1'b0 : reset_out[3];
        end
    end
endmodule