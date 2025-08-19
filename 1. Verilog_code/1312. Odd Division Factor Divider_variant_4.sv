//SystemVerilog
module odd_div #(parameter DIV = 3) (
    input clk_i, reset_i,
    output reg clk_o
);
    // Goldschmidt division algorithm signals
    reg [7:0] numerator;
    reg [7:0] denominator;
    reg [7:0] factor;
    reg [7:0] result;
    reg [2:0] iter_count;
    reg compute_done;
    
    // State machine signals
    reg [1:0] state;
    reg [1:0] next_state;
    localparam IDLE = 2'b00, COMPUTE = 2'b01, WAIT = 2'b10;
    
    // Counter
    reg [$clog2(DIV)-1:0] counter;
    
    // State register update
    always @(posedge clk_i) begin
        if (reset_i) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                next_state = COMPUTE;
            end
                
            COMPUTE: begin
                if (iter_count >= 3'b011) begin
                    next_state = WAIT;
                end
            end
                
            WAIT: begin
                if (counter == DIV - 1) begin
                    next_state = IDLE;
                end
            end
                
            default: next_state = IDLE;
        endcase
    end
    
    // Counter logic
    always @(posedge clk_i) begin
        if (reset_i) begin
            counter <= 0;
        end
        else if (state == WAIT) begin
            if (counter == DIV - 1) begin
                counter <= 0;
            end
            else begin
                counter <= counter + 1;
            end
        end
    end
    
    // Clock output generation
    always @(posedge clk_i) begin
        if (reset_i) begin
            clk_o <= 0;
        end
        else if (state == WAIT && counter == DIV - 1) begin
            clk_o <= ~clk_o;
        end
    end
    
    // Goldschmidt algorithm initialization
    always @(posedge clk_i) begin
        if (reset_i) begin
            numerator <= 8'd128;  // Fixed point 1.0 (scaled by 128)
            denominator <= DIV << 5;  // Scale by 32 for fixed-point
            iter_count <= 0;
            compute_done <= 0;
        end
        else if (state == IDLE) begin
            numerator <= 8'd128;  // Fixed point 1.0
            denominator <= DIV << 5;
            iter_count <= 0;
            compute_done <= 0;
        end
    end
    
    // Goldschmidt algorithm calculation
    always @(posedge clk_i) begin
        if (reset_i) begin
            factor <= 0;
            result <= 0;
        end
        else if (state == COMPUTE) begin
            if (iter_count < 3'b011) begin  // 3 iterations
                // Goldschmidt iteration
                factor <= 8'd255 - denominator[7:0] + 8'd1;  // 2 - D
                numerator <= (numerator * factor) >> 7;
                denominator <= (denominator * factor) >> 7;
                iter_count <= iter_count + 1;
            end
            else begin
                result <= numerator;  // Result is N/D
                compute_done <= 1;
            end
        end
    end
endmodule