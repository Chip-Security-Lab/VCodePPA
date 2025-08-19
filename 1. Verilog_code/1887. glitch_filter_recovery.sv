module glitch_filter_recovery (
    input wire clk,
    input wire rst_n,
    input wire noisy_input,
    output reg clean_output
);
    reg [3:0] shift_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 4'b0000;
            clean_output <= 1'b0;
        end else begin
            shift_reg <= {shift_reg[2:0], noisy_input};
            
            // Only change output if we see 3 or more of the same bit
            case (shift_reg)
                4'b0000: clean_output <= 1'b0;
                4'b0001: clean_output <= clean_output;
                4'b0010: clean_output <= clean_output;
                4'b0011: clean_output <= clean_output;
                4'b0100: clean_output <= clean_output;
                4'b0101: clean_output <= clean_output;
                4'b0110: clean_output <= clean_output;
                4'b0111: clean_output <= 1'b1;
                4'b1000: clean_output <= clean_output;
                4'b1001: clean_output <= clean_output;
                4'b1010: clean_output <= clean_output;
                4'b1011: clean_output <= 1'b1;
                4'b1100: clean_output <= clean_output;
                4'b1101: clean_output <= 1'b1;
                4'b1110: clean_output <= 1'b1;
                4'b1111: clean_output <= 1'b1;
            endcase
        end
    end
endmodule