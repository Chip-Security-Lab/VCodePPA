//SystemVerilog
// SystemVerilog IEEE 1364-2005
module gray_counter #(parameter WIDTH = 8) (
    input wire clk, reset, enable,
    output reg [WIDTH-1:0] gray_out,
    output reg valid_out
);
    // Pipeline stage registers
    reg [WIDTH-1:0] binary_stage1;
    reg [WIDTH-1:0] binary_stage2;
    reg enable_stage1, enable_stage2;
    reg valid_stage1, valid_stage2;
    
    // Stage 1: Increment binary counter
    reg [WIDTH-1:0] next_binary_stage1;
    
    always @(*) begin
        next_binary_stage1 = binary_stage1 + enable;
    end
    
    // Stage 2: Convert binary to gray code
    reg [WIDTH-1:0] next_gray_stage2;
    
    always @(*) begin
        next_gray_stage2 = (binary_stage2 >> 1) ^ binary_stage2;
    end
    
    // Pipeline registers update
    always @(posedge clk) begin
        if (reset) begin
            // Reset all pipeline stages
            binary_stage1 <= {WIDTH{1'b0}};
            binary_stage2 <= {WIDTH{1'b0}};
            gray_out <= {WIDTH{1'b0}};
            
            // Reset control signals
            enable_stage1 <= 1'b0;
            enable_stage2 <= 1'b0;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            // Stage 1 registers
            binary_stage1 <= next_binary_stage1;
            enable_stage1 <= enable;
            valid_stage1 <= enable || valid_stage1;
            
            // Stage 2 registers
            binary_stage2 <= binary_stage1;
            enable_stage2 <= enable_stage1;
            valid_stage2 <= valid_stage1;
            
            // Output registers
            gray_out <= next_gray_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule