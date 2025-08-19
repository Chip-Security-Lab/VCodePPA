//SystemVerilog
module watchdog_reset_gen #(
    parameter TIMEOUT = 8
)(
    input wire clk,
    input wire watchdog_kick,
    output reg watchdog_reset
);
    reg [3:0] counter;
    reg timeout_reached;
    
    always @(posedge clk) begin
        // Counter update logic
        if (watchdog_kick) begin
            counter <= 4'b0000;
        end else if (counter < TIMEOUT) begin
            counter <= counter + 1'b1;
        end
        
        // Pre-compute timeout condition
        timeout_reached <= (counter == TIMEOUT - 1) && !watchdog_kick;
        
        // Use pre-computed value to set watchdog_reset
        watchdog_reset <= timeout_reached || (counter >= TIMEOUT && !watchdog_kick);
    end
endmodule