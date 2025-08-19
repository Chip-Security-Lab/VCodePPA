//SystemVerilog
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
    reg counter_reached_timeout;
    reg enable_watchdog_reg;
    reg clear_watchdog_reg;
    reg [TIMEOUT_WIDTH-1:0] timeout_value_reg;
    wire timeout_condition;
    
    // Register inputs to improve timing at input boundaries
    always @(posedge clk_in) begin
        enable_watchdog_reg <= enable_watchdog;
        clear_watchdog_reg <= clear_watchdog;
        timeout_value_reg <= timeout_value;
    end
    
    // Pre-compute timeout condition
    assign timeout_condition = (watchdog_counter >= timeout_value_reg);
    
    // Reusable counter module with limit functionality
    counter_with_limit #(
        .WIDTH(TIMEOUT_WIDTH)
    ) watchdog_count (
        .clk(clk_in),
        .reset(clear_watchdog_reg),
        .enable(enable_watchdog_reg && !counter_reached_timeout),
        .counter_out(watchdog_counter)
    );
    
    // Timeout detection logic
    always @(posedge clk_in) begin
        if (clear_watchdog_reg) begin
            counter_reached_timeout <= 1'b0;
        end else if (enable_watchdog_reg) begin
            counter_reached_timeout <= timeout_condition;
        end
    end
    
    // System reset generation logic
    always @(posedge clk_in) begin
        if (clear_watchdog_reg) begin
            system_reset <= 1'b0;
        end else if (enable_watchdog_reg && counter_reached_timeout) begin
            system_reset <= 1'b1;
        end
    end
endmodule

// Reusable counter module with limit functionality
module counter_with_limit #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire reset,
    input wire enable,
    output reg [WIDTH-1:0] counter_out
);
    always @(posedge clk) begin
        if (reset) begin
            counter_out <= {WIDTH{1'b0}};
        end else if (enable) begin
            counter_out <= counter_out + 1'b1;
        end
    end
endmodule