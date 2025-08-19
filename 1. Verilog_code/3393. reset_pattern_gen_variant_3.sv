//SystemVerilog
module reset_pattern_gen(
    input wire clk,
    input wire trigger,
    input wire [7:0] pattern,
    output reg [7:0] reset_seq
);
    reg [2:0] bit_pos;
    reg trigger_reg;
    reg [7:0] pattern_reg;
    
    // Register input signals to reduce input-to-register delay
    always @(posedge clk) begin
        trigger_reg <= trigger;
        pattern_reg <= pattern;
    end
    
    // Main logic with retimed registers
    always @(posedge clk) begin
        if (trigger_reg) begin
            bit_pos <= 3'b0;
            reset_seq <= 8'h0;
        end else if (bit_pos < 3'b111) begin
            bit_pos <= bit_pos + 1'b1;
            reset_seq[bit_pos] <= pattern_reg[bit_pos];
        end
    end
endmodule