//SystemVerilog
module fsm_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire start,
    input  wire done,
    output wire clk_out
);
    // FSM states definition
    localparam IDLE = 1'b0, ACTIVE = 1'b1;
    
    // Pipeline stage registers
    reg state_stage1;
    reg state_stage2;
    
    // Valid signals for pipeline control
    reg valid_stage1;
    reg valid_stage2;
    
    // Pipeline stage 1: State calculation
    reg next_state;
    
    always @(*) begin
        if (state_stage1 == IDLE) begin
            if (start) begin
                next_state = ACTIVE;
            end
            else begin
                next_state = IDLE;
            end
        end
        else begin // state_stage1 == ACTIVE
            if (done) begin
                next_state = IDLE;
            end
            else begin
                next_state = ACTIVE;
            end
        end
    end
    
    // Pipeline registers update
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline stages
            state_stage1 <= IDLE;
            state_stage2 <= IDLE;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            // Stage 1 update
            state_stage1 <= next_state;
            valid_stage1 <= 1'b1;
            
            // Stage 2 update
            state_stage2 <= state_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output clock gating in final pipeline stage
    assign clk_out = clk_in & (state_stage2 == ACTIVE) & valid_stage2;
endmodule