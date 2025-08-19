//SystemVerilog
//IEEE 1364-2005 Verilog
module fsm_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire start,
    input  wire done,
    output wire clk_out
);
    // Pipeline control signals
    wire valid_stage1_next, valid_stage2_next, valid_stage3_next;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Pipeline FSM states
    localparam IDLE = 1'b0, ACTIVE = 1'b1;
    reg state_stage1, state_stage2, state_stage3;
    wire next_state_stage1;
    reg next_state_stage2;
    
    // Input registration stage (Pipeline stage 1)
    reg start_stage1, done_stage1;
    
    // Combined logic - Stage 1 next state calculation
    fsm_next_state_logic stage1_comb (
        .current_state(state_stage1),
        .start(start_stage1),
        .done(done_stage1),
        .next_state(next_state_stage1)
    );
    
    // Assignment for control signals - combinational logic
    assign valid_stage1_next = rst_n ? 1'b1 : 1'b0; // Data valid after reset
    assign valid_stage2_next = valid_stage1;
    assign valid_stage3_next = valid_stage2;
    
    // Sequential logic - Stage 1: Input registration
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            start_stage1 <= 1'b0;
            done_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            start_stage1 <= start;
            done_stage1 <= done;
            valid_stage1 <= valid_stage1_next;
        end
    end
    
    // Sequential logic - Stage 2: State transition processing
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            next_state_stage2 <= IDLE;
            valid_stage2 <= 1'b0;
        end else begin
            state_stage2 <= state_stage1;
            next_state_stage2 <= next_state_stage1;
            valid_stage2 <= valid_stage2_next;
        end
    end
    
    // Sequential logic - Stage 3: Final state update
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            state_stage3 <= IDLE;
            valid_stage3 <= 1'b0;
        end else begin
            state_stage1 <= next_state_stage2; // Feedback path for state update
            state_stage3 <= state_stage2;
            valid_stage3 <= valid_stage3_next;
        end
    end
    
    // Combinational logic - Clock gating control
    clock_gate_control clk_gate_comb (
        .clk_in(clk_in),
        .valid(valid_stage3),
        .state(state_stage3),
        .clk_out(clk_out)
    );
endmodule

// Separate module for next state logic (combinational)
module fsm_next_state_logic (
    input wire current_state,
    input wire start,
    input wire done,
    output reg next_state
);
    // Localparam for states
    localparam IDLE = 1'b0, ACTIVE = 1'b1;
    
    // Pure combinational logic for next state
    always @(*) begin
        case (current_state)
            IDLE:   next_state = start ? ACTIVE : IDLE;
            ACTIVE: next_state = done ? IDLE : ACTIVE;
            default: next_state = IDLE;
        endcase
    end
endmodule

// Separate module for clock gating control (combinational)
module clock_gate_control (
    input wire clk_in,
    input wire valid,
    input wire state,
    output wire clk_out
);
    // Localparam for states
    localparam IDLE = 1'b0, ACTIVE = 1'b1;
    
    // Clock gating pure combinational logic
    assign clk_out = clk_in & valid & (state == ACTIVE);
endmodule