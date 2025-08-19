//SystemVerilog
module multiplier_high_priority (
    input clk,
    input rst_n,
    input [7:0] a,
    input [7:0] b,
    input valid_in,
    output reg ready_in,
    output reg [15:0] product,
    output reg valid_out,
    input ready_out
);
    reg [15:0] result;
    reg [7:0] a_reg, b_reg;
    reg calc_done;
    
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam WAIT = 2'b10;
    
    reg [1:0] state, next_state;
    wire state_idle = (state == IDLE);
    wire state_calc = (state == CALC);
    wire state_wait = (state == WAIT);
    
    // State machine with reduced combinational logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            result <= 16'b0;
            calc_done <= 1'b0;
            valid_out <= 1'b0;
            ready_in <= 1'b1;
        end else begin
            state <= next_state;
            
            // Optimized data path with parallel processing
            if (state_idle & valid_in) begin
                a_reg <= a;
                b_reg <= b;
                ready_in <= 1'b0;
            end
            
            if (state_calc) begin
                result <= a_reg * b_reg;
                calc_done <= 1'b1;
            end
            
            if (state_wait) begin
                valid_out <= ~ready_out;
                if (ready_out) begin
                    calc_done <= 1'b0;
                end
            end
            
            if (state_idle) begin
                valid_out <= 1'b0;
                ready_in <= 1'b1;
            end
        end
    end
    
    // Optimized next state logic with balanced paths
    always @(*) begin
        case (state)
            IDLE: next_state = valid_in ? CALC : IDLE;
            CALC: next_state = WAIT;
            WAIT: next_state = ready_out ? IDLE : WAIT;
            default: next_state = IDLE;
        endcase
    end
    
    // Direct output assignment
    assign product = result;
endmodule