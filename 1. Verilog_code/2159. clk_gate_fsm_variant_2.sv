//SystemVerilog
module clk_gate_fsm (
    input clk, rst, en,
    output reg [1:0] state_out
);

    parameter S0=0, S1=1, S2=2;
    
    // Pipeline stage registers
    reg [1:0] state_stage1;
    reg [1:0] state_stage2;
    
    // Pipeline enable signals
    reg en_stage1, en_stage2;
    
    // Combined pipeline stages with same clock and reset conditions
    always @(posedge clk) begin
        if (rst) begin
            // Reset all pipeline stages
            state_stage1 <= S0;
            en_stage1 <= 0;
            state_stage2 <= S0;
            en_stage2 <= 0;
            state_out <= S0;
        end else begin
            // Stage 1: Input capture and state determination
            en_stage1 <= en;
            if (en) begin
                case(state_out)
                    S0: state_stage1 <= S1;
                    S1: state_stage1 <= S2;
                    S2: state_stage1 <= S0;
                    default: state_stage1 <= S0;
                endcase
            end else begin
                state_stage1 <= state_out;
            end
            
            // Stage 2: Intermediate processing
            en_stage2 <= en_stage1;
            state_stage2 <= state_stage1;
            
            // Stage 3: Output generation
            if (en_stage2) begin
                state_out <= state_stage2;
            end
        end
    end
    
endmodule