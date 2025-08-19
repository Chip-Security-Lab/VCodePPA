//SystemVerilog
// SystemVerilog
module range_detector_active_low(
    input wire clock, reset,
    input wire [7:0] value,
    input wire [7:0] range_low, range_high,
    output reg range_valid_n
);

    // Pipeline stage 1 registers
    reg [7:0] value_stage1;
    reg [7:0] range_low_stage1;
    reg [7:0] range_high_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg comp_result_stage2;
    reg valid_stage2;
    
    // Internal comparison signals
    reg comp_low, comp_high;

    // Stage 1: Register value input
    always @(posedge clock) begin
        if (reset) begin
            value_stage1 <= 8'b0;
        end else begin
            value_stage1 <= value;
        end
    end
    
    // Stage 1: Register range bounds
    always @(posedge clock) begin
        if (reset) begin
            range_low_stage1 <= 8'b0;
            range_high_stage1 <= 8'b0;
        end else begin
            range_low_stage1 <= range_low;
            range_high_stage1 <= range_high;
        end
    end
    
    // Stage 1: Register valid signal
    always @(posedge clock) begin
        if (reset) begin
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Calculate lower bound comparison
    always @(posedge clock) begin
        if (reset) begin
            comp_low <= 1'b0;
        end else begin
            comp_low <= (value_stage1 < range_low_stage1);
        end
    end
    
    // Stage 2: Calculate upper bound comparison
    always @(posedge clock) begin
        if (reset) begin
            comp_high <= 1'b0;
        end else begin
            comp_high <= (value_stage1 > range_high_stage1);
        end
    end
    
    // Stage 2: Combine comparisons and register result
    always @(posedge clock) begin
        if (reset) begin
            comp_result_stage2 <= 1'b1;
        end else begin
            comp_result_stage2 <= comp_low || comp_high;
        end
    end
    
    // Stage 2: Register valid signal
    always @(posedge clock) begin
        if (reset) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end

    // Output stage: Generate final output
    always @(posedge clock) begin
        if (reset) begin
            range_valid_n <= 1'b1;
        end else if (valid_stage2) begin
            range_valid_n <= comp_result_stage2;
        end
    end

endmodule