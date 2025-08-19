//SystemVerilog
module serial_bit_comparator(
    input clk,
    input reset,
    input bit_a,         // Serial data input A
    input bit_b,         // Serial data input B
    input start_compare, // Start the comparison process
    input bit_valid,     // Indicates valid bits are present
    output reg match,    // Final result: 1 if all bits matched
    output reg busy      // Comparator is processing
);
    // FSM states
    localparam IDLE = 2'b00;
    localparam COMPARING = 2'b01;
    localparam COMPLETE = 2'b10;
    
    reg [1:0] state, next_state;
    
    // Buffer registers for high fanout signals
    reg [1:0] idle_buf1, idle_buf2;
    reg [1:0] next_state_buf1, next_state_buf2;
    reg bit_a_buf, bit_b_buf;
    
    // Pipeline registers for critical path cutting
    reg start_compare_pipe;
    reg bit_valid_pipe;
    reg bit_match_pipe;
    reg [1:0] state_pipe;
    
    // Buffer register update logic
    always @(posedge clk) begin
        idle_buf1 <= IDLE;
        idle_buf2 <= idle_buf1;
        
        next_state_buf1 <= next_state;
        next_state_buf2 <= next_state_buf1;
        
        bit_a_buf <= bit_a;
        bit_b_buf <= bit_b;
        
        // Pipeline register updates
        start_compare_pipe <= start_compare;
        bit_valid_pipe <= bit_valid;
        bit_match_pipe <= (bit_a_buf == bit_b_buf);
        state_pipe <= state;
    end
    
    // State machine logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= idle_buf2;  // Use buffered IDLE
            match <= 1'b0;
            busy <= 1'b0;
        end else begin
            state <= next_state_buf1;  // Use buffered next_state
            
            case (state_pipe)
                idle_buf2: begin  // Use buffered IDLE
                    if (start_compare_pipe) begin
                        match <= 1'b1;  // Start with assumption of match
                        busy <= 1'b1;
                    end
                end
                
                COMPARING: begin
                    if (bit_valid_pipe && !bit_match_pipe) begin  // Use pipelined signals
                        match <= 1'b0;  // Mismatch detected
                    end
                end
                
                COMPLETE: begin
                    busy <= 1'b0;
                end
            endcase
        end
    end
    
    // Next state logic - split into multiple stages to reduce fanout
    reg [1:0] interim_state;
    
    // First stage of next state logic
    always @(*) begin
        case (state)
            idle_buf1: interim_state = start_compare ? COMPARING : idle_buf1;
            COMPARING: interim_state = !bit_valid ? COMPLETE : COMPARING;
            COMPLETE: interim_state = idle_buf1;
            default: interim_state = idle_buf1;
        endcase
    end
    
    // Second stage to reduce fanout
    always @(*) begin
        next_state = interim_state;
    end
endmodule