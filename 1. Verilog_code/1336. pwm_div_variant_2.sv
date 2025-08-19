//SystemVerilog
module pwm_div #(
    parameter HIGH = 3,  // High pulse duration
    parameter LOW  = 5   // Low pulse duration
)(
    input  wire       clk,    // System clock
    input  wire       rst_n,  // Active-low reset
    output reg        out     // PWM output signal
);

    // ===== Constants and Parameters =====
    localparam PERIOD      = HIGH + LOW;
    localparam TOTAL_COUNT = PERIOD - 1;
    localparam COUNT_WIDTH = 8;  // Fixed width for counter
    
    // ===== Stage 1: Counter and Phase Detection =====
    reg  [COUNT_WIDTH-1:0] counter_stage1_r;
    wire [COUNT_WIDTH-1:0] counter_next_w;
    wire                   period_end_w;
    wire                   high_phase_w;
    
    // Counter logic with reduced path depth
    assign period_end_w    = (counter_stage1_r == TOTAL_COUNT);
    assign high_phase_w    = (counter_stage1_r < HIGH);
    assign counter_next_w  = period_end_w ? {COUNT_WIDTH{1'b0}} : counter_stage1_r + 1'b1;
    
    // Stage 1 registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1_r <= {COUNT_WIDTH{1'b0}};
        end else begin
            counter_stage1_r <= counter_next_w;
        end
    end
    
    // ===== Stage 2: Control Signal Generation =====
    reg period_end_stage2_r;   // Pipeline register for period end detection
    reg high_phase_stage2_r;   // Pipeline register for high phase detection
    
    // Stage 2 registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            period_end_stage2_r  <= 1'b0;
            high_phase_stage2_r  <= 1'b0;
        end else begin
            period_end_stage2_r  <= period_end_w;
            high_phase_stage2_r  <= high_phase_w;
        end
    end
    
    // ===== Stage 3: Output Generation =====
    wire pwm_output_w;
    
    // Simplified output logic path
    assign pwm_output_w = high_phase_stage2_r || period_end_stage2_r;
    
    // Final output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 1'b0;
        end else begin
            out <= pwm_output_w;
        end
    end

endmodule