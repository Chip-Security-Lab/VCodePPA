//SystemVerilog
module serial_bit_comparator(
    input clk,
    input reset,
    input bit_a,         // Serial data input A
    input bit_b,         // Serial data input B
    input req,           // Request to start comparison
    output reg ack,      // Acknowledge the request
    output reg match,    // Final result: 1 if all bits matched
    output reg busy      // Comparator is processing
);
    // FSM states
    localparam IDLE = 2'b00;
    localparam COMPARING = 2'b01;
    localparam COMPLETE = 2'b10;
    
    reg [1:0] state, next_state;
    reg req_prev;
    
    // State machine logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            match <= 1'b0;
            busy <= 1'b0;
            ack <= 1'b0;
            req_prev <= 1'b0;
        end else begin
            state <= next_state;
            req_prev <= req;
            
            case (state)
                IDLE: begin
                    if (req && !req_prev) begin
                        match <= 1'b1;  // Start with assumption of match
                        busy <= 1'b1;
                        ack <= 1'b1;
                    end
                end
                
                COMPARING: begin
                    // Optimized comparison using a single condition
                    match <= match && (bit_a == bit_b);
                end
                
                COMPLETE: begin
                    busy <= 1'b0;
                    ack <= 1'b0;
                end
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (req && !req_prev)
                    next_state = COMPARING;
            end
            
            COMPARING: begin
                if (!req)
                    next_state = COMPLETE;
            end
            
            COMPLETE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
endmodule