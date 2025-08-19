//SystemVerilog
module phase_locked_clk(
    input ref_clk,
    input target_clk,
    input rst,
    output reg clk_out,
    output reg locked
);
    // State encoding optimization - use one-hot encoding for better timing
    localparam [1:0] PHASE_0 = 2'b01;
    localparam [1:0] PHASE_1 = 2'b10;
    
    reg [1:0] phase_state;
    reg ref_detect, target_detect;
    
    // Pre-compute next state values with optimized comparisons
    wire phase_toggle = (phase_state == PHASE_0);
    wire is_last_phase = (phase_state == PHASE_1);
    wire next_locked = target_detect || is_last_phase;
    wire next_clk_out = phase_toggle ? ~clk_out : clk_out;
    reg [1:0] next_phase_state;
    
    // Optimized state transition logic
    always @(*) begin
        if (target_detect)
            next_phase_state = PHASE_0;
        else if (is_last_phase)
            next_phase_state = PHASE_0;
        else
            next_phase_state = phase_state << 1;
    end
    
    // Sequential logic for ref_clk domain with reset synchronization
    always @(posedge ref_clk or posedge rst) begin
        if (rst) begin
            ref_detect <= 1'b0;
            phase_state <= PHASE_0;
            locked <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            ref_detect <= 1'b1;
            phase_state <= next_phase_state;
            locked <= next_locked;
            clk_out <= next_clk_out;
        end
    end
    
    // Optimized target_clk domain logic with single-cycle latency
    always @(posedge target_clk or posedge rst) begin
        if (rst) 
            target_detect <= 1'b0;
        else 
            target_detect <= ref_detect;
    end
endmodule