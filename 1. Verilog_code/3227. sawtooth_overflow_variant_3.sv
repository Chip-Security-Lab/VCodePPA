//SystemVerilog
module sawtooth_overflow(
    input clk,
    input rst,
    input [7:0] increment,
    output reg [7:0] sawtooth,
    output reg overflow
);
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Stage 1: Input registration
    reg [7:0] increment_stage1;
    reg [7:0] sawtooth_current;
    
    // Stage 2: Addition and overflow detection
    reg [7:0] increment_stage2;
    reg [7:0] sawtooth_stage2;
    reg [8:0] sum_stage2;
    reg valid_sum_stage2;
    
    // Stage 3: Output processing
    reg [7:0] sawtooth_stage3;
    reg overflow_stage3;
    
    // Stage 1: Input registration
    always @(posedge clk) begin
        if (rst) begin
            increment_stage1 <= 8'd0;
            sawtooth_current <= 8'd0;
            valid_stage1 <= 1'b0;
        end else begin
            increment_stage1 <= increment;
            sawtooth_current <= sawtooth;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Calculation
    always @(posedge clk) begin
        if (rst) begin
            increment_stage2 <= 8'd0;
            sawtooth_stage2 <= 8'd0;
            sum_stage2 <= 9'd0;
            valid_stage2 <= 1'b0;
        end else begin
            increment_stage2 <= increment_stage1;
            sawtooth_stage2 <= sawtooth_current;
            sum_stage2 <= {1'b0, sawtooth_current} + {1'b0, increment_stage1};
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Result processing
    always @(posedge clk) begin
        if (rst) begin
            sawtooth_stage3 <= 8'd0;
            overflow_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            sawtooth_stage3 <= sum_stage2[7:0];
            overflow_stage3 <= sum_stage2[8];
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output registers
    always @(posedge clk) begin
        if (rst) begin
            sawtooth <= 8'd0;
            overflow <= 1'b0;
        end else if (valid_stage3) begin
            sawtooth <= sawtooth_stage3;
            overflow <= overflow_stage3;
        end
    end
endmodule