module counter_reset_gen #(
    parameter THRESHOLD = 10
)(
    input wire clk,
    input wire enable,
    output reg reset_out
);
    reg [3:0] counter;
    always @(posedge clk) begin
        if (!enable)
            counter <= 4'b0;
        else if (counter < THRESHOLD)
            counter <= counter + 1'b1;
        
        reset_out <= (counter == THRESHOLD) ? 1'b1 : 1'b0;
    end
endmodule