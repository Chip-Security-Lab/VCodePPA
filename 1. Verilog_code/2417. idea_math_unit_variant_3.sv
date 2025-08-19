//SystemVerilog
module idea_math_unit (
    input clk,
    input reset_n,
    
    // Control signal
    input mul_en,
    
    // Input data with valid-ready handshake
    input [15:0] x,
    input [15:0] y,
    input valid_in,
    output reg ready_in,
    
    // Output data with valid-ready handshake
    output reg [15:0] result,
    output reg valid_out,
    input ready_out
);
    // Internal registers and wires
    reg [15:0] x_reg, y_reg;
    reg mul_en_reg;
    wire [31:0] mul_temp;
    reg [15:0] result_next;
    
    // Pipelined multiplication result
    assign mul_temp = x_reg * y_reg;
    
    // FSM states
    localparam IDLE = 2'b00,
               COMPUTE = 2'b01,
               WAIT_OUTPUT = 2'b10;
    
    reg [1:0] state, next_state;
    
    // State machine - synchronous part
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            x_reg <= 16'h0;
            y_reg <= 16'h0;
            mul_en_reg <= 1'b0;
            result <= 16'h0;
            valid_out <= 1'b0;
        end else begin
            state <= next_state;
            
            // Input capture on valid-ready handshake
            if (state == IDLE && valid_in && ready_in) begin
                x_reg <= x;
                y_reg <= y;
                mul_en_reg <= mul_en;
            end
            
            // Result update
            if (state == COMPUTE) begin
                result <= result_next;
                valid_out <= 1'b1;
            end
            
            // Clear valid when handshake completes
            if (valid_out && ready_out) begin
                valid_out <= 1'b0;
            end
        end
    end
    
    // Next state logic and result computation
    always @(*) begin
        // Default values
        next_state = state;
        ready_in = (state == IDLE);
        result_next = result;
        
        case (state)
            IDLE: begin
                if (valid_in && ready_in)
                    next_state = COMPUTE;
            end
            
            COMPUTE: begin
                // Compute result
                if (mul_en_reg) begin
                    result_next = (mul_temp == 32'h0) ? 16'hFFFF : 
                                 (mul_temp % 17'h10001);
                end else begin
                    result_next = (x_reg + y_reg) % 65536;
                end
                
                next_state = WAIT_OUTPUT;
            end
            
            WAIT_OUTPUT: begin
                if (valid_out && ready_out)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
endmodule