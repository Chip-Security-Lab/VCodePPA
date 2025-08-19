//SystemVerilog
module glitch_filter_recovery (
    input wire clk,
    input wire rst_n,
    input wire noisy_input,
    output reg clean_output
);
    // IEEE 1364-2005 Verilog
    reg [3:0] shift_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 4'b0000;
            clean_output <= 1'b0;
        end else begin
            shift_reg <= {shift_reg[2:0], noisy_input};
            
            // Use conditional operator to determine output based on bit count
            clean_output <= (shift_reg == 4'b0000) ? 1'b0 :
                           ((shift_reg == 4'b0111) || 
                            (shift_reg == 4'b1011) || 
                            (shift_reg == 4'b1101) || 
                            (shift_reg == 4'b1110) || 
                            (shift_reg == 4'b1111)) ? 1'b1 : 
                            clean_output;
        end
    end
endmodule