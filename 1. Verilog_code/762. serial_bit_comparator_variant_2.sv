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
    
    // State registers
    reg [1:0] state, next_state;
    
    // Buffer registers for high fan-out signals
    reg [1:0] idle_buf1, idle_buf2;
    reg [1:0] next_state_buf1, next_state_buf2;
    reg bit_a_buf, bit_b_buf;
    reg bit_valid_buf;
    
    // Buffer the high fan-out signals
    always @(posedge clk) begin
        idle_buf1 <= IDLE;
        idle_buf2 <= idle_buf1;
        
        next_state_buf1 <= next_state;
        next_state_buf2 <= next_state_buf1;
        
        bit_a_buf <= bit_a;
        bit_b_buf <= bit_b;
        bit_valid_buf <= bit_valid;
    end
    
    // State machine logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= idle_buf2;
            match <= 1'b0;
            busy <= 1'b0;
        end else begin
            state <= next_state_buf2;
            
            case (state)
                idle_buf2: begin
                    if (start_compare) begin
                        match <= 1'b1;  // Start with assumption of match
                        busy <= 1'b1;
                    end
                end
                
                COMPARING: begin
                    if (bit_valid_buf && (bit_a_buf != bit_b_buf)) begin
                        match <= 1'b0;  // Mismatch detected
                    end
                end
                
                COMPLETE: begin
                    busy <= 1'b0;
                end
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            idle_buf2: begin
                if (start_compare)
                    next_state = COMPARING;
            end
            
            COMPARING: begin
                if (!bit_valid_buf)
                    next_state = COMPLETE;
            end
            
            COMPLETE: begin
                next_state = idle_buf2;
            end
            
            default: next_state = idle_buf2;
        endcase
    end
endmodule