//SystemVerilog
module glitch_filter_recovery (
    input wire clk,
    input wire rst_n,
    input wire noisy_input,
    output reg clean_output
);
    reg [3:0] shift_reg;
    wire [3:0] ones_count;
    
    // Shift register logic - handles sampling of input signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 4'b0000;
        end else begin
            shift_reg <= {shift_reg[2:0], noisy_input};
        end
    end
    
    // Count the number of 1's in the shift register
    assign ones_count = shift_reg[0] + shift_reg[1] + shift_reg[2] + shift_reg[3];
    
    // Output decision logic with case statement instead of if-else cascade
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clean_output <= 1'b0;
        end else begin
            case (ones_count)
                4'd0, 4'd1: 
                    clean_output <= 1'b0;
                4'd3, 4'd4: 
                    clean_output <= 1'b1;
                default: 
                    clean_output <= clean_output; // Keep previous value for ones_count=2
            endcase
        end
    end
endmodule