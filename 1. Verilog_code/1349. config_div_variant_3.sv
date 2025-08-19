//SystemVerilog
module config_div #(parameter MODE=0) (
    input wire clk,
    input wire rst,
    output reg clk_out
);
    // Define divider parameter based on MODE
    localparam DIV = (MODE) ? 8 : 16;
    
    // Divider state and control registers
    reg [4:0] dividend;        // Current dividend value
    reg [4:0] divisor;         // Divisor value
    reg [4:0] quotient;        // Result quotient
    reg [2:0] shift_count;     // Position tracker
    reg divider_busy;          // Divider operation in progress
    reg divider_done;          // Division completed
    
    // State machine states
    localparam IDLE = 2'b00;
    localparam DIVIDE = 2'b01;
    localparam DONE = 2'b10;
    reg [1:0] state;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2;
    reg clk_toggle;
    
    // Optimized divider implementation
    always @(posedge clk) begin
        if (rst) begin
            dividend <= 5'b0;
            divisor <= (MODE) ? 5'd8 : 5'd16;
            quotient <= 5'b0;
            shift_count <= 3'b0;
            divider_busy <= 1'b0;
            divider_done <= 1'b0;
            state <= IDLE;
            valid_stage1 <= 1'b0;
            clk_toggle <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    // Initialize division operation
                    dividend <= 5'd31;  // Max count value
                    divisor <= (MODE) ? 5'd8 : 5'd16;
                    quotient <= 5'b0;
                    shift_count <= 5;   // Start from MSB position
                    divider_busy <= 1'b1;
                    divider_done <= 1'b0;
                    state <= DIVIDE;
                    valid_stage1 <= 1'b0;
                end
                
                DIVIDE: begin
                    if (shift_count > 0) begin
                        // Optimized subtraction test with single comparison
                        quotient[shift_count-1] <= (dividend >= divisor);
                        
                        // Conditional subtraction based on comparison result
                        dividend <= (dividend >= divisor) ? (dividend - divisor) : dividend;
                        
                        // Shift the divisor right
                        divisor <= {1'b0, divisor[4:1]};
                        shift_count <= shift_count - 1'b1;
                    end else begin
                        // Division complete
                        divider_busy <= 1'b0;
                        divider_done <= 1'b1;
                        state <= DONE;
                        valid_stage1 <= 1'b1;
                    end
                end
                
                DONE: begin
                    // Direct comparison with parameterized value
                    if (quotient == DIV-1) begin
                        clk_toggle <= ~clk_toggle;
                    end
                    
                    // Restart division process
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // Pipeline stage 2 - registered signals
    always @(posedge clk) begin
        if (rst) begin
            valid_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Final output update with single-stage pipeline
    always @(posedge clk) begin
        if (rst) begin
            clk_out <= 1'b0;
        end else if (valid_stage2) begin
            clk_out <= clk_toggle;
        end
    end
    
endmodule