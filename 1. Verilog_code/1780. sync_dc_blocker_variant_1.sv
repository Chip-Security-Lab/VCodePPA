//SystemVerilog
module sync_dc_blocker #(
    parameter WIDTH = 16
)(
    input clk, reset,
    input [WIDTH-1:0] signal_in,
    output reg [WIDTH-1:0] signal_out
);
    // Pipeline stage registers
    reg [WIDTH-1:0] prev_in_stage1;
    reg [WIDTH-1:0] prev_out_stage1;
    reg [WIDTH-1:0] signal_in_stage1;
    
    reg [WIDTH-1:0] diff_stage2;
    reg [WIDTH-1:0] prev_out_scaled_stage2;
    
    reg [WIDTH-1:0] temp_stage3;

    // Two's complement subtraction signals
    wire [WIDTH-1:0] prev_in_comp;
    wire [WIDTH-1:0] diff_raw;
    wire diff_carry;
    
    // Barrel shifter signals for scaling by 7/8
    wire [WIDTH-1:0] prev_out_mul_7;
    
    // Two's complement subtraction logic
    assign prev_in_comp = ~prev_in_stage1 + 1'b1;
    assign {diff_carry, diff_raw} = signal_in_stage1 + prev_in_comp;
    
    // Multiply by 7 using shifts and additions
    // 7 = 4 + 2 + 1 = 2^2 + 2^1 + 2^0
    assign prev_out_mul_7 = {prev_out_stage1[WIDTH-3:0], 2'b00} + {prev_out_stage1[WIDTH-2:0], 1'b0} + prev_out_stage1;
    
    // Stage 1: Input capture and synchronization
    always @(posedge clk) begin
        if (reset) begin
            prev_in_stage1 <= 0;
            prev_out_stage1 <= 0;
            signal_in_stage1 <= 0;
        end else begin
            prev_in_stage1 <= signal_in;
            prev_out_stage1 <= temp_stage3;
            signal_in_stage1 <= signal_in;
        end
    end
    
    // Stage 2: Compute difference and scaling
    // Barrel shifter implementation for division by 8 (shift right by 3)
    always @(posedge clk) begin
        if (reset) begin
            diff_stage2 <= 0;
            prev_out_scaled_stage2 <= 0;
        end else begin
            diff_stage2 <= diff_raw;
            // Barrel shifter for right shift by 3
            prev_out_scaled_stage2 <= {
                {3{prev_out_mul_7[WIDTH-1]}}, // Sign extension for signed arithmetic
                prev_out_mul_7[WIDTH-1:3]
            };
        end
    end
    
    // Stage 3: Final summation
    always @(posedge clk) begin
        if (reset) begin
            temp_stage3 <= 0;
            signal_out <= 0;
        end else begin
            temp_stage3 <= diff_stage2 + prev_out_scaled_stage2;
            signal_out <= temp_stage3;
        end
    end
endmodule