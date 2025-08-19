module watchdog_timer #(
    parameter TIMEOUT_WIDTH = 20
)(
    input wire clk_in,
    input wire clear_watchdog,
    input wire enable_watchdog,
    input wire [TIMEOUT_WIDTH-1:0] timeout_value,
    output reg system_reset
);
    reg [TIMEOUT_WIDTH-1:0] watchdog_counter;
    
    always @(posedge clk_in) begin
        if (clear_watchdog) begin
            watchdog_counter <= {TIMEOUT_WIDTH{1'b0}};
            system_reset <= 1'b0;
        end else if (enable_watchdog) begin
            if (watchdog_counter >= timeout_value) begin
                system_reset <= 1'b1;
            end else begin
                watchdog_counter <= watchdog_counter + 1'b1;
            end
        end
    end
endmodule
