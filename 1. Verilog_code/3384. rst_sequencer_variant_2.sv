//SystemVerilog
module rst_sequencer(
    input  wire       clk,
    input  wire       rst_trigger,
    output reg  [3:0] rst_stages
);
    // ===== Reset Sequencing Pipeline =====
    // Pipeline stage signals
    reg        rst_trigger_d1, rst_trigger_d2;   // Pipelined reset trigger
    reg [2:0]  counter;                          // Reset sequence counter
    reg        pipe_valid_d1, pipe_valid_d2;     // Pipeline validity control
    reg [3:0]  rst_pattern;                      // Intermediate reset pattern
    
    // ===== Stage 1: Input Capture and Counter Control =====
    always @(posedge clk) begin
        // Register input and generate valid signal
        rst_trigger_d1 <= rst_trigger;
        pipe_valid_d1  <= 1'b1;
        
        // Counter logic - reset or increment up to max value
        if (rst_trigger) begin
            counter <= 3'b000;
        end else if (counter < 3'b111) begin
            counter <= counter + 3'b001;
        end
    end
    
    // ===== Stage 2: Reset Pattern Generation =====
    always @(posedge clk) begin
        // Pipeline control signals
        rst_trigger_d2 <= rst_trigger_d1;
        pipe_valid_d2  <= pipe_valid_d1;
        
        // Generate reset pattern based on trigger and counter
        if (rst_trigger_d1) begin
            // Full reset pattern when triggered
            rst_pattern <= 4'b1111;
        end else if (counter < 3'b111 && pipe_valid_d1) begin
            // Shift reset pattern during sequence
            rst_pattern <= rst_stages >> 1;
        end
    end
    
    // ===== Stage 3: Output Assignment =====
    always @(posedge clk) begin
        if (pipe_valid_d2) begin
            // Final output selection based on trigger state
            rst_stages <= rst_trigger_d2 ? 4'b1111 : rst_pattern;
        end
    end
endmodule