//SystemVerilog
module fsm_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire start,
    input  wire done,
    output wire clk_out
);
    // State encoding
    localparam IDLE = 1'b0, ACTIVE = 1'b1;
    
    // Pipeline stage registers
    reg state_q, state_d;
    reg state_stage1_q;
    reg start_stage1_q, done_stage1_q;
    reg valid_stage1_q;
    
    // Pipeline stage 2 registers
    reg state_stage2_q;
    reg valid_stage2_q;
    
    // Input pipeline registers - Stage 1
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            start_stage1_q <= 1'b0;
            done_stage1_q <= 1'b0;
            valid_stage1_q <= 1'b0;
        end else begin
            start_stage1_q <= start;
            done_stage1_q <= done;
            valid_stage1_q <= 1'b1; // Valid signal for pipeline control
        end
    end
    
    // State transition logic - Stage 1
    always @(*) begin
        case (state_q)
            IDLE:   state_d = start_stage1_q ? ACTIVE : IDLE;
            ACTIVE: state_d = done_stage1_q ? IDLE : ACTIVE;
            default: state_d = IDLE;
        endcase
    end
    
    // Pipeline registers for Stage 1 to Stage 2
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1_q <= IDLE;
            state_q <= IDLE;
        end else begin
            state_q <= state_d;
            state_stage1_q <= state_q;
        end
    end
    
    // Pipeline Stage 2
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2_q <= IDLE;
            valid_stage2_q <= 1'b0;
        end else begin
            state_stage2_q <= state_stage1_q;
            valid_stage2_q <= valid_stage1_q;
        end
    end
    
    // Clock gating logic with glitch-free implementation
    reg enable_latch;
    reg enable_stage1_q, enable_stage2_q;
    
    // Compute enable signal through pipeline
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage1_q <= 1'b0;
            enable_stage2_q <= 1'b0;
        end else begin
            enable_stage1_q <= (state_q == ACTIVE);
            enable_stage2_q <= enable_stage1_q;
        end
    end
    
    // Transparent latch for glitch-free clock gating
    always @(*) begin
        if (!clk_in)
            enable_latch = enable_stage2_q & valid_stage2_q;
    end
    
    // Final gated clock output
    assign clk_out = clk_in & enable_latch;
    
endmodule