//SystemVerilog
module sequence_clock_gen(
    input clk,
    input rst,
    input [7:0] pattern,
    output reg seq_out
);
    // Pipeline registers
    reg [7:0] pattern_reg;
    reg [2:0] bit_pos;
    reg valid_pattern;
    reg valid_bit_pos;
    
    // Pattern registration and validation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pattern_reg <= 8'd0;
            valid_pattern <= 1'b0;
        end else begin
            pattern_reg <= pattern;
            valid_pattern <= 1'b1;
        end
    end
    
    // Bit position counter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_pos <= 3'd0;
        end else begin
            bit_pos <= bit_pos + 3'd1;
        end
    end
    
    // Validation pipeline
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_bit_pos <= 1'b0;
        end else begin
            valid_bit_pos <= valid_pattern;
        end
    end
    
    // Output generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            seq_out <= 1'b0;
        end else begin
            seq_out <= valid_bit_pos ? pattern_reg[bit_pos] : 1'b0;
        end
    end
endmodule