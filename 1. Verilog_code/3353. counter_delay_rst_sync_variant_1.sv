//SystemVerilog
module counter_delay_rst_sync #(
    parameter DELAY_CYCLES = 16
)(
    input  wire clk,
    input  wire raw_rst_n,
    output reg  delayed_rst_n
);
    // Synchronization and control signals
    reg raw_rst_n_meta;
    reg raw_rst_n_sync;
    reg counting_active;
    reg [4:0] delay_counter;
    
    // Reset synchronization - moved registers after combinational logic
    always @(posedge clk) begin
        raw_rst_n_meta <= raw_rst_n;
        raw_rst_n_sync <= raw_rst_n_meta;
    end
    
    // Counter control logic with optimized reset handling
    always @(posedge clk) begin
        if (!raw_rst_n_sync) begin
            // Reset state
            counting_active <= 1'b0;
            delay_counter <= 5'b00000;
            delayed_rst_n <= 1'b0;
        end else begin
            if (!counting_active) begin
                // Start counting
                counting_active <= 1'b1;
                delay_counter <= 5'b00000;
                delayed_rst_n <= 1'b0;
            end else if (delay_counter < DELAY_CYCLES - 1) begin
                // Continue counting
                counting_active <= 1'b1;
                delay_counter <= delay_counter + 1'b1;
                delayed_rst_n <= 1'b0;
            end else begin
                // Counting complete
                counting_active <= 1'b1;
                delay_counter <= delay_counter;
                delayed_rst_n <= 1'b1;
            end
        end
    end
endmodule