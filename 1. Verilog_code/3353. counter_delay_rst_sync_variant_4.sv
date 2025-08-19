//SystemVerilog
module counter_delay_rst_sync #(
    parameter DELAY_CYCLES = 16
)(
    input  wire clk,
    input  wire raw_rst_n,
    output reg  delayed_rst_n
);
    // Meta-stability synchronizer (moved after combinational logic)
    reg raw_rst_n_ff;
    reg [1:0] sync_stages;
    
    // Counter with optimal bit width based on DELAY_CYCLES
    reg [$clog2(DELAY_CYCLES):0] delay_counter;
    // State tracking flag
    reg counting_done;
    
    // First stage register to capture input
    always @(posedge clk) begin
        raw_rst_n_ff <= raw_rst_n;
    end
    
    // Main processing logic
    always @(posedge clk) begin
        if (!raw_rst_n_ff) begin
            sync_stages <= 2'b00;
            delay_counter <= {($clog2(DELAY_CYCLES)+1){1'b0}};
            delayed_rst_n <= 1'b0;
            counting_done <= 1'b0;
        end else begin
            // Synchronize reset signal
            sync_stages <= {sync_stages[0], 1'b1};
            
            // Counter control logic optimized to reduce comparisons
            if (sync_stages[1] && !counting_done) begin
                // Increment counter until threshold
                if (delay_counter == DELAY_CYCLES - 1) begin
                    delayed_rst_n <= 1'b1;
                    counting_done <= 1'b1;
                end else begin
                    delay_counter <= delay_counter + 1'b1;
                end
            end
        end
    end
endmodule