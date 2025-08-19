//SystemVerilog
module skip_state_ring_counter(
    input wire clock,
    input wire reset,
    input wire skip, // Skip next state
    output reg [3:0] state
);
    // Define one-hot state encoding
    localparam [3:0] STATE_0 = 4'b0001;
    localparam [3:0] STATE_1 = 4'b0010;
    localparam [3:0] STATE_2 = 4'b0100;
    localparam [3:0] STATE_3 = 4'b1000;
    
    // Internal pipeline registers
    reg skip_r;
    reg [3:0] next_state;
    
    // Stage 1: Control signal registration
    always @(posedge clock) begin
        if (reset)
            skip_r <= 1'b0;
        else
            skip_r <= skip;
    end
    
    // Stage 2: Next state calculation
    always @(*) begin
        case (state)
            STATE_0: next_state = skip_r ? STATE_2 : STATE_1;
            STATE_1: next_state = skip_r ? STATE_3 : STATE_2;
            STATE_2: next_state = skip_r ? STATE_0 : STATE_3;
            STATE_3: next_state = skip_r ? STATE_1 : STATE_0;
            default: next_state = STATE_0;
        endcase
    end
    
    // Stage 3: State update
    always @(posedge clock) begin
        if (reset)
            state <= STATE_0;
        else
            state <= next_state;
    end
endmodule