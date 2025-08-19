//SystemVerilog
module serial_bit_comparator(
    input clk,
    input reset,
    input bit_a,         // Serial data input A
    input bit_b,         // Serial data input B
    input valid,         // Valid signal for data
    output reg ready,    // Ready signal for data
    output reg match,    // Final result: 1 if all bits matched
    output reg busy      // Comparator is processing
);

    // FSM states
    localparam IDLE = 2'b00;
    localparam COMPARING = 2'b01;
    localparam COMPLETE = 2'b10;
    
    reg [1:0] state, next_state;
    reg comparison_started;
    
    // Signed multiplication optimization signals
    reg signed [1:0] bit_a_signed;
    reg signed [1:0] bit_b_signed;
    wire signed [3:0] mult_result;
    reg signed [3:0] mult_reg;
    
    // Convert inputs to signed
    always @(*) begin
        bit_a_signed = {1'b0, bit_a};
        bit_b_signed = {1'b0, bit_b};
    end
    
    // Optimized signed multiplication
    assign mult_result = bit_a_signed * bit_b_signed;
    
    // Register multiplication result
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mult_reg <= 4'b0;
        end else begin
            mult_reg <= mult_result;
        end
    end
    
    // State machine logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            match <= 1'b0;
            busy <= 1'b0;
            ready <= 1'b1;
            comparison_started <= 1'b0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    if (valid && ready) begin
                        match <= 1'b1;
                        busy <= 1'b1;
                        comparison_started <= 1'b1;
                        ready <= 1'b0;
                    end else begin
                        ready <= 1'b1;
                    end
                end
                
                COMPARING: begin
                    if (valid && ready) begin
                        if (mult_reg[0] != 1'b1) begin
                            match <= 1'b0;
                        end
                        ready <= 1'b0;
                    end else if (!valid && comparison_started) begin
                        ready <= 1'b1;
                    end
                end
                
                COMPLETE: begin
                    busy <= 1'b0;
                    comparison_started <= 1'b0;
                    ready <= 1'b1;
                end
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (valid && ready)
                    next_state = COMPARING;
            end
            
            COMPARING: begin
                if (!valid && comparison_started)
                    next_state = COMPLETE;
            end
            
            COMPLETE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
endmodule