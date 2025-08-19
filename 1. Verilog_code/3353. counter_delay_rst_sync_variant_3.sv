//SystemVerilog
module counter_delay_rst_sync #(
    parameter DELAY_CYCLES = 16
)(
    input  wire clk,
    input  wire raw_rst_n,
    output reg  delayed_rst_n
);
    // Synchronizer
    reg [1:0] sync_stages;
    
    // Counter control
    reg counting;
    reg sync_complete;
    
    // Counter operation
    reg [4:0] delay_counter;
    
    // Combined always block for all stages with same trigger condition
    always @(posedge clk or negedge raw_rst_n) begin
        if (!raw_rst_n) begin
            // Reset all registers
            sync_stages <= 2'b00;
            counting <= 1'b0;
            sync_complete <= 1'b0;
            delay_counter <= 5'b00000;
            delayed_rst_n <= 1'b0;
        end else begin
            // Stage 1: Synchronizer logic
            sync_stages <= {sync_stages[0], 1'b1};
            
            // Stage 2: Counter control logic
            sync_complete <= sync_stages[1];
            
            if (sync_stages[1] && !counting)
                counting <= 1'b1;
                
            // Stage 3: Counter operation
            if (counting) begin
                if (delay_counter < DELAY_CYCLES - 1)
                    delay_counter <= delay_counter + 1;
            end
            
            // Stage 4: Reset generation
            if (counting && (delay_counter >= DELAY_CYCLES - 1))
                delayed_rst_n <= 1'b1;
        end
    end
    
endmodule