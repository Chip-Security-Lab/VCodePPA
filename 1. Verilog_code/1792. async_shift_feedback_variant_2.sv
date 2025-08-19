//SystemVerilog
module async_shift_feedback #(
    parameter LENGTH = 8,
    parameter TAPS = 4'b1001  // Example: taps at positions 0 and 3
)(
    input wire clk,           // Clock input for pipelining
    input wire rst_n,         // Reset input
    input wire data_in,
    input wire [LENGTH-1:0] current_reg,
    output reg next_bit,
    output reg [LENGTH-1:0] next_reg
);

    // ===== STAGE 1: Tap Selection =====
    // Select bits from the shift register based on TAPS pattern
    wire [LENGTH-1:0] tapped_bits_s1;
    reg [LENGTH-1:0] tapped_bits_reg;
    
    assign tapped_bits_s1 = current_reg & TAPS;
    
    // ===== STAGE 2: Feedback Calculation =====
    // XOR the selected taps to generate feedback
    wire feedback_s2;
    reg feedback_reg;
    
    assign feedback_s2 = ^tapped_bits_reg;
    
    // ===== STAGE 3: Data Mixing =====
    // Combine feedback with input data
    wire mixed_bit_s3;
    reg mixed_bit_reg;
    
    assign mixed_bit_s3 = feedback_reg ^ data_in;
    
    // ===== STAGE 4: Shift Register Update =====
    // Prepare next register state with shifted values
    wire [LENGTH-1:0] shifted_data_s4;
    
    assign shifted_data_s4 = {current_reg[LENGTH-2:0], mixed_bit_reg};
    
    // ===== Pipeline Registers =====
    // Sequential logic for multi-stage pipelined operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            tapped_bits_reg <= {LENGTH{1'b0}};
            feedback_reg <= 1'b0;
            mixed_bit_reg <= 1'b0;
            next_bit <= 1'b0;
            next_reg <= {LENGTH{1'b0}};
        end else begin
            // Pipeline stage registers
            tapped_bits_reg <= tapped_bits_s1;
            feedback_reg <= feedback_s2;
            mixed_bit_reg <= mixed_bit_s3;
            
            // Output registers
            next_bit <= mixed_bit_reg;
            next_reg <= shifted_data_s4;
        end
    end

endmodule