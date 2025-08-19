//SystemVerilog
module adaptive_threshold_recovery (
    input wire clk,
    input wire reset,
    input wire [7:0] signal_in,
    input wire [7:0] noise_level,
    output reg [7:0] signal_out,
    output reg signal_valid
);
    // Pipeline stage 1 registers
    reg [7:0] signal_in_stage1;
    reg [7:0] noise_level_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [7:0] signal_in_stage2;
    reg [7:0] noise_level_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [7:0] signal_in_stage3;
    reg [7:0] noise_base_stage3;
    reg valid_stage3;
    
    // Pipeline stage 4 registers
    reg [7:0] signal_in_stage4;
    reg [7:0] threshold_stage4;
    reg valid_stage4;
    
    // Pipeline stage 5 registers
    reg [7:0] signal_in_stage5;
    reg [7:0] threshold_stage5;
    reg valid_stage5;
    
    // Intermediate signals for threshold calculation
    wire [7:0] noise_shifted = noise_level_stage2 >> 1;
    wire [7:0] noise_base = 8'd64;
    
    // Pipeline stage 1: Input registration
    always @(posedge clk) begin
        if (reset) begin
            signal_in_stage1 <= 8'd0;
            noise_level_stage1 <= 8'd0;
            valid_stage1 <= 1'b0;
        end else begin
            signal_in_stage1 <= signal_in;
            noise_level_stage1 <= noise_level;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline stage 2: Prepare for threshold calculation
    always @(posedge clk) begin
        if (reset) begin
            signal_in_stage2 <= 8'd0;
            noise_level_stage2 <= 8'd0;
            valid_stage2 <= 1'b0;
        end else begin
            signal_in_stage2 <= signal_in_stage1;
            noise_level_stage2 <= noise_level_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3: Process shifted value and base
    always @(posedge clk) begin
        if (reset) begin
            signal_in_stage3 <= 8'd0;
            noise_base_stage3 <= 8'd0;
            valid_stage3 <= 1'b0;
        end else begin
            signal_in_stage3 <= signal_in_stage2;
            noise_base_stage3 <= noise_base;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Pipeline stage 4: Complete threshold calculation
    always @(posedge clk) begin
        if (reset) begin
            signal_in_stage4 <= 8'd0;
            threshold_stage4 <= 8'd128;
            valid_stage4 <= 1'b0;
        end else begin
            signal_in_stage4 <= signal_in_stage3;
            threshold_stage4 <= noise_base_stage3 + noise_shifted;
            valid_stage4 <= valid_stage3;
        end
    end
    
    // Pipeline stage 5: Prepare for threshold comparison
    always @(posedge clk) begin
        if (reset) begin
            signal_in_stage5 <= 8'd0;
            threshold_stage5 <= 8'd0;
            valid_stage5 <= 1'b0;
        end else begin
            signal_in_stage5 <= signal_in_stage4;
            threshold_stage5 <= threshold_stage4;
            valid_stage5 <= valid_stage4;
        end
    end
    
    // Pipeline stage 6: Output generation
    always @(posedge clk) begin
        if (reset) begin
            signal_out <= 8'd0;
            signal_valid <= 1'b0;
        end else if (valid_stage5) begin
            // Apply threshold
            if (signal_in_stage5 > threshold_stage5) begin
                signal_out <= signal_in_stage5;
                signal_valid <= 1'b1;
            end else begin
                signal_out <= 8'd0;
                signal_valid <= 1'b0;
            end
        end else begin
            signal_out <= 8'd0;
            signal_valid <= 1'b0;
        end
    end
endmodule