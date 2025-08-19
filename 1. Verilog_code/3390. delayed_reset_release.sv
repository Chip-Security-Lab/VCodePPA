module delayed_reset_release(
    input wire clk,
    input wire reset_in,
    input wire [3:0] delay_value,
    output reg reset_out
);
    reg [3:0] counter;
    always @(posedge clk) begin
        if (reset_in) begin
            counter <= delay_value;
            reset_out <= 1'b1;
        end else if (counter > 0) begin
            counter <= counter - 1'b1;
            reset_out <= 1'b1;
        end else
            reset_out <= 1'b0;
    end
endmodule