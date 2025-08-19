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
    // Stage 1: Input Capture and Control Logic
    reg [1:0] control_stage1;
    reg [TIMEOUT_WIDTH-1:0] timeout_value_stage1;
    reg [TIMEOUT_WIDTH-1:0] watchdog_counter;
    reg valid_stage1;
    
    // Stage 2: Processing Logic
    reg [1:0] control_stage2;
    reg [TIMEOUT_WIDTH-1:0] watchdog_counter_stage2;
    reg [TIMEOUT_WIDTH-1:0] timeout_value_stage2;
    reg valid_stage2;
    reg counter_increment_stage2;
    reg reset_counter_stage2;
    reg system_reset_stage2;
    
    // Stage 3: Output Stage
    reg system_reset_stage3;
    reg [TIMEOUT_WIDTH-1:0] watchdog_counter_stage3;

    // Stage 1: Input Capture and Control Decode
    always @(posedge clk_in) begin
        // Input registration
        control_stage1 <= {clear_watchdog, enable_watchdog};
        timeout_value_stage1 <= timeout_value;
        valid_stage1 <= 1'b1; // Always valid in this design
    end
    
    // Stage 2: Processing Logic
    always @(posedge clk_in) begin
        // Pass along control signals to stage 2
        control_stage2 <= control_stage1;
        timeout_value_stage2 <= timeout_value_stage1;
        valid_stage2 <= valid_stage1;
        watchdog_counter_stage2 <= watchdog_counter;
        
        // Default values
        counter_increment_stage2 <= 1'b0;
        reset_counter_stage2 <= 1'b0;
        system_reset_stage2 <= system_reset;
        
        // Only process if valid
        if (valid_stage1) begin
            case(control_stage1)
                2'b10, 2'b11: begin  // clear_watchdog takes priority
                    reset_counter_stage2 <= 1'b1;
                    system_reset_stage2 <= 1'b0;
                end
                2'b01: begin  // enable_watchdog true, clear_watchdog false
                    if (watchdog_counter >= timeout_value_stage1) begin
                        system_reset_stage2 <= 1'b1;
                    end else begin
                        counter_increment_stage2 <= 1'b1;
                    end
                end
                2'b00: begin
                    // Maintain current state
                end
            endcase
        end
    end
    
    // Stage 3: Counter Update and Output Stage
    always @(posedge clk_in) begin
        // Forward system reset signal to output
        system_reset <= system_reset_stage2;
        
        // Update counter based on stage 2 decisions
        if (reset_counter_stage2) begin
            watchdog_counter <= {TIMEOUT_WIDTH{1'b0}};
        end else if (counter_increment_stage2) begin
            watchdog_counter <= watchdog_counter + 1'b1;
        end
        
        // Store updated counter for feedback
        watchdog_counter_stage3 <= watchdog_counter;
    end
endmodule