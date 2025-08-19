module watchdog_reset_gen #(
    parameter TIMEOUT = 8
)(
    input wire clk,
    input wire watchdog_kick,
    output reg watchdog_reset
);
    reg [3:0] counter;
    always @(posedge clk) begin
        if (watchdog_kick)
            counter <= 0;
        else if (counter < TIMEOUT)
            counter <= counter + 1'b1;
        
        watchdog_reset <= (counter >= TIMEOUT);
    end
endmodule