//SystemVerilog
module WindowAvgRecovery #(parameter WIDTH=8, DEPTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] din,
    input valid_in,
    output reg valid_out,
    output reg [WIDTH-1:0] dout
);
    // Buffer for input samples
    reg [WIDTH-1:0] buffer [0:DEPTH-1];
    
    // Pipeline registers for partial sums
    reg [WIDTH:0] sum_stage1_a;  // First pair sum
    reg [WIDTH:0] sum_stage1_b;  // Second pair sum
    reg [WIDTH+1:0] sum_stage2;  // Total sum
    
    // Pipeline valid signals
    reg valid_stage1, valid_stage2;
    
    integer i;

    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset all registers and buffers
            for (i = 0; i < DEPTH; i = i + 1) begin
                buffer[i] <= 0;
            end
            
            // Reset pipeline registers
            sum_stage1_a <= 0;
            sum_stage1_b <= 0;
            sum_stage2 <= 0;
            dout <= 0;
            
            // Reset control signals
            valid_stage1 <= 0;
            valid_stage2 <= 0;
            valid_out <= 0;
        end else begin
            // Stage 0: Input stage - shift buffer and load new sample
            if (valid_in) begin
                for (i = DEPTH-1; i > 0; i = i - 1) begin
                    buffer[i] <= buffer[i-1];
                end
                buffer[0] <= din;
            end
            
            // Stage 1: First level of addition - calculate partial sums
            sum_stage1_a <= buffer[0] + buffer[1];
            sum_stage1_b <= buffer[2] + buffer[3];
            valid_stage1 <= valid_in;
            
            // Stage 2: Second level of addition - combine partial sums
            sum_stage2 <= sum_stage1_a + sum_stage1_b;
            valid_stage2 <= valid_stage1;
            
            // Stage 3: Final division (shift right by 2)
            dout <= sum_stage2 >> 2;
            valid_out <= valid_stage2;
        end
    end
endmodule