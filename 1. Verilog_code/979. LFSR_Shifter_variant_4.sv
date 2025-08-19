//SystemVerilog
module LFSR_Shifter #(parameter WIDTH=8, TAPS=8'b10001110) (
    input clk, rst,
    output serial_out
);
    reg [WIDTH-1:0] lfsr;
    reg feedback_bit_reg;
    wire feedback_bit;
    
    // Compute the feedback bit combinationally
    assign feedback_bit = ^(lfsr & TAPS);
    
    // Register the feedback bit to break the critical path
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            feedback_bit_reg <= 1'b1;
        end else begin
            feedback_bit_reg <= feedback_bit;
        end
    end
    
    // Main LFSR shift register with registered feedback
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr <= {WIDTH{1'b1}};
        end else begin
            lfsr <= {lfsr[WIDTH-2:0], feedback_bit_reg};
        end
    end
    
    // Output assignment
    assign serial_out = lfsr[WIDTH-1];
endmodule