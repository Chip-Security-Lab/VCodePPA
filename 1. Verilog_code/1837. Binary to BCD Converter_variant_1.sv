//SystemVerilog
module bin2bcd_converter #(parameter BIN_WIDTH = 8, parameter DIGITS = 3) (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    input  wire [BIN_WIDTH-1:0] binary_in,
    output reg  [DIGITS*4-1:0] bcd_out,
    output reg  done
);

    // State definitions using one-hot encoding for faster state transitions
    localparam IDLE   = 4'b0001;
    localparam SHIFT  = 4'b0010;
    localparam CHECK  = 4'b0100;
    localparam ADJUST = 4'b1000;
    
    reg [3:0] state, next_state;
    reg [BIN_WIDTH-1:0] binary_reg;
    reg [$clog2(BIN_WIDTH):0] bit_counter; // Extra bit to avoid underflow condition
    reg [$clog2(DIGITS):0] digit_counter;  // Extra bit for boundary condition
    reg [DIGITS*4-1:0] bcd_temp;
    
    // State transition logic with synchronous reset for better timing
    always @(posedge clk) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Optimized next state logic using one-hot encoding
    always @(*) begin
        next_state = IDLE; // Default case for safety
        
        case (1'b1) // Case based on one-hot bit
            state[0]: // IDLE
                next_state = start ? SHIFT : IDLE;
            
            state[1]: // SHIFT
                next_state = CHECK;
            
            state[2]: // CHECK
                next_state = (digit_counter >= DIGITS-1) ? ADJUST : CHECK;
            
            state[3]: // ADJUST
                next_state = (bit_counter == 0) ? IDLE : SHIFT;
            
            default: next_state = IDLE;
        endcase
    end
    
    // Optimized data path logic with improved comparison operations
    always @(posedge clk) begin
        if (!rst_n) begin
            bcd_out <= {DIGITS*4{1'b0}};
            binary_reg <= {BIN_WIDTH{1'b0}};
            bit_counter <= BIN_WIDTH;
            digit_counter <= 0;
            bcd_temp <= {DIGITS*4{1'b0}};
            done <= 1'b0;
        end
        else begin
            // Default assignments to avoid latches
            done <= done;
            bcd_out <= bcd_out;
            
            case (1'b1) // One-hot encoded state
                state[0]: begin // IDLE
                    if (start) begin
                        binary_reg <= binary_in;
                        bit_counter <= BIN_WIDTH;
                        bcd_temp <= {DIGITS*4{1'b0}};
                        done <= 1'b0;
                    end
                end
                
                state[1]: begin // SHIFT
                    // Combined shift operation in a single step
                    bcd_temp <= {bcd_temp[DIGITS*4-2:0], binary_reg[bit_counter-1]};
                    bit_counter <= bit_counter - 1;
                    digit_counter <= 0;
                end
                
                state[2]: begin // CHECK
                    // Optimized comparison - uses >= 5 instead of > 4 (same effect but potentially better implementation)
                    // Uses parallel adjustment for all digits for faster operation
                    if (digit_counter < DIGITS) begin
                        if (bcd_temp[digit_counter*4 +: 4] >= 4'd5) begin
                            bcd_temp[digit_counter*4 +: 4] <= bcd_temp[digit_counter*4 +: 4] + 4'd3;
                        end
                        digit_counter <= digit_counter + 1;
                    end
                end
                
                state[3]: begin // ADJUST
                    if (bit_counter == 0) begin
                        done <= 1'b1;
                        bcd_out <= bcd_temp; // Update output when processing completes
                    end
                end
            endcase
        end
    end

endmodule