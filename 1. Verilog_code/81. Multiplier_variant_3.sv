//SystemVerilog
module Multiplier1(
    input clk,           // Clock signal added
    input rst_n,         // Reset signal added
    input [7:0] a, b,    // Input operands
    input ready,         // Ready signal from receiver
    output reg valid,    // Valid signal to receiver
    output reg [15:0] result // Result of multiplication
);
    // Internal signals
    reg [7:0] a_reg, b_reg;
    reg calc_done;
    
    // State definition
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    
    // Buffer registers for high fanout signals
    reg idle_buf, idle_buf2;
    reg [1:0] next_state_buf;
    reg b0_buf;
    
    // State machine - sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            valid <= 1'b0;
            result <= 16'b0;
            calc_done <= 1'b0;
            idle_buf <= 1'b0;
            idle_buf2 <= 1'b0;
            next_state_buf <= 2'b00;
            b0_buf <= 1'b0;
        end else begin
            state <= next_state;
            
            // Buffer register updates
            idle_buf <= (state == IDLE);
            idle_buf2 <= idle_buf;
            next_state_buf <= next_state;
            b0_buf <= (state == 2'b00);
            
            case (state)
                IDLE: begin
                    if (ready) begin
                        a_reg <= a;
                        b_reg <= b;
                    end
                    valid <= 1'b0;
                    calc_done <= 1'b0;
                end
                
                CALC: begin
                    result <= a_reg * b_reg;
                    calc_done <= 1'b1;
                end
                
                DONE: begin
                    valid <= 1'b1;
                    if (ready && valid) begin
                        valid <= 1'b0;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
    // State machine - combinational logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (ready) next_state = CALC;
            end
            
            CALC: begin
                if (calc_done) next_state = DONE;
            end
            
            DONE: begin
                if (ready && valid) next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
endmodule