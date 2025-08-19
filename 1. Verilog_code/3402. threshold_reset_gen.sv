module threshold_reset_gen(
    input wire clk,
    input wire [7:0] signal_value,
    input wire [7:0] threshold,
    output reg reset_out
);
    always @(posedge clk) begin
        if (signal_value > threshold)
            reset_out <= 1'b1;
        else
            reset_out <= 1'b0;
    end
endmodule