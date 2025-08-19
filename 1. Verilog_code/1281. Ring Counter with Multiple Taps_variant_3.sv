//SystemVerilog
module tapped_ring_counter(
    input wire clock,
    input wire reset,
    output reg [3:0] state,
    output wire tap1, tap2 // Tapped outputs
);
    // Pipeline stage registers
    reg [3:0] state_stage1;
    reg [3:0] state_stage2;
    reg [3:0] state_stage3;
    
    // Fan-out distribution buffers
    reg [3:0] tap1_buffer_stage1, tap1_buffer_stage2;
    reg [3:0] tap2_buffer_stage1, tap2_buffer_stage2;
    
    // Tap output signals
    reg tap1_reg, tap2_reg;
    
    // Assign tapped outputs through registered paths
    assign tap1 = tap1_reg;
    assign tap2 = tap2_reg;
    
    // Pipeline stage 1: Compute next state
    always @(posedge clock) begin
        if (reset)
            state_stage1 <= 4'b0001;
        else
            state_stage1 <= {state[2:0], state[3]};
    end
    
    // Pipeline stage 2: Propagate state
    always @(posedge clock) begin
        state_stage2 <= state_stage1;
    end
    
    // Pipeline stage 3: Final state update
    always @(posedge clock) begin
        state_stage3 <= state_stage2;
        state <= state_stage3;
    end
    
    // Tap1 buffer pipeline
    always @(posedge clock) begin
        tap1_buffer_stage1 <= state;
        tap1_buffer_stage2 <= tap1_buffer_stage1;
        tap1_reg <= tap1_buffer_stage2[1];
    end
    
    // Tap2 buffer pipeline
    always @(posedge clock) begin
        tap2_buffer_stage1 <= state;
        tap2_buffer_stage2 <= tap2_buffer_stage1;
        tap2_reg <= tap2_buffer_stage2[3];
    end
endmodule