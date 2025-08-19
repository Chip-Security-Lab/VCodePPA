//SystemVerilog
module or_gate_2input_4bit (
    input  wire        clk,        // Clock input
    input  wire        rst_n,      // Active low reset
    input  wire [3:0]  a,          // First input operand
    input  wire [3:0]  b,          // Second input operand
    output reg  [3:0]  y           // Pipelined output result
);

    // Stage 1: Register input operands to improve timing
    reg [3:0] a_stage1, b_stage1;
    
    // Stage 2: Intermediate result
    reg [3:0] result_stage2;
    
    // Multi-stage pipelined datapath
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            // Reset all pipeline registers
            a_stage1 <= 4'b0;
            b_stage1 <= 4'b0;
            result_stage2 <= 4'b0;
            y <= 4'b0;
        end else begin
            // Stage 1: Register inputs
            a_stage1 <= a;
            b_stage1 <= b;
            
            // Stage 2: Perform OR operation and register result
            result_stage2 <= a_stage1 | b_stage1;
            
            // Final stage: Register output
            y <= result_stage2;
        end
    end

endmodule