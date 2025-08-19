//SystemVerilog
module arithmetic_encoder #(
    parameter PRECISION = 16
)(
    input                     clk,
    input                     rst,
    input                     symbol_valid,
    input              [7:0]  symbol,
    output reg                code_valid,
    output reg [PRECISION-1:0] lower_bound,
    output reg [PRECISION-1:0] upper_bound
);
    // Simplified probability model (fixed)
    reg [PRECISION-1:0] prob_table [0:3];
    
    // LUT for probability ranges based on symbol MSB
    reg [PRECISION-1:0] prob_low_lut [0:3];
    reg [PRECISION-1:0] prob_high_lut [0:3];
    
    // Pipeline stage registers
    reg                     valid_stage1, valid_stage2, valid_stage3;
    reg [7:0]               symbol_stage1;
    reg [1:0]               symbol_msb_stage1, symbol_msb_stage2;
    reg [PRECISION-1:0]     lower_bound_stage1, lower_bound_stage2, lower_bound_stage3;
    reg [PRECISION-1:0]     upper_bound_stage1;
    reg [PRECISION-1:0]     range_stage1, range_stage2, range_stage3;
    reg [PRECISION-1:0]     prob_low_stage2, prob_high_stage2;
    reg [PRECISION-1:0]     range_prob_low_stage3, range_prob_high_stage3;
    
    // Combinational logic signals
    wire [PRECISION-1:0]    range_current;
    wire [1:0]              symbol_msb;
    
    // Initialize the probability tables
    initial begin
        prob_table[0] = 0;                   // Start
        prob_table[1] = PRECISION/4;         // 25%
        prob_table[2] = PRECISION/2;         // 50%
        prob_table[3] = (3*PRECISION)/4;     // 75%
        
        // Pre-compute probability lookup tables
        for (int i = 0; i < 4; i++) begin
            prob_low_lut[i] = prob_table[i];
            prob_high_lut[i] = prob_table[i+1];
        end
    end
    
    // Calculate the current range (combinational)
    assign range_current = upper_bound - lower_bound + 1;
    assign symbol_msb = symbol[7:6];
    
    // Pipeline Stage 1: Capture input and calculate range
    always @(posedge clk) begin
        if (rst) begin
            valid_stage1 <= 1'b0;
            symbol_stage1 <= 8'b0;
            symbol_msb_stage1 <= 2'b0;
            lower_bound_stage1 <= 0;
            upper_bound_stage1 <= {PRECISION{1'b1}};
            range_stage1 <= 0;
        end else begin
            valid_stage1 <= symbol_valid;
            if (symbol_valid) begin
                symbol_stage1 <= symbol;
                symbol_msb_stage1 <= symbol_msb;
                lower_bound_stage1 <= lower_bound;
                upper_bound_stage1 <= upper_bound;
                range_stage1 <= range_current;
            end
        end
    end
    
    // Pipeline Stage 2: Lookup probability values using LUT
    always @(posedge clk) begin
        if (rst) begin
            valid_stage2 <= 1'b0;
            symbol_msb_stage2 <= 2'b0;
            lower_bound_stage2 <= 0;
            range_stage2 <= 0;
            prob_low_stage2 <= 0;
            prob_high_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                symbol_msb_stage2 <= symbol_msb_stage1;
                lower_bound_stage2 <= lower_bound_stage1;
                range_stage2 <= range_stage1;
                // Direct LUT access instead of conditional logic
                prob_low_stage2 <= prob_low_lut[symbol_msb_stage1];
                prob_high_stage2 <= prob_high_lut[symbol_msb_stage1];
            end
        end
    end
    
    // Pipeline Stage 3: Calculate partial products
    always @(posedge clk) begin
        if (rst) begin
            valid_stage3 <= 1'b0;
            lower_bound_stage3 <= 0;
            range_stage3 <= 0;
            range_prob_low_stage3 <= 0;
            range_prob_high_stage3 <= 0;
        end else begin
            valid_stage3 <= valid_stage2;
            if (valid_stage2) begin
                lower_bound_stage3 <= lower_bound_stage2;
                range_stage3 <= range_stage2;
                // Multiply range by probability values from LUT
                range_prob_low_stage3 <= (range_stage2 * prob_low_stage2);
                range_prob_high_stage3 <= (range_stage2 * prob_high_stage2);
            end
        end
    end
    
    // Pipeline Stage 4: Final calculation and output
    always @(posedge clk) begin
        if (rst) begin
            code_valid <= 1'b0;
            lower_bound <= 0;
            upper_bound <= {PRECISION{1'b1}};
        end else begin
            code_valid <= valid_stage3;
            if (valid_stage3) begin
                // Apply calculated bounds
                lower_bound <= lower_bound_stage3 + (range_prob_low_stage3/PRECISION);
                upper_bound <= lower_bound_stage3 + (range_prob_high_stage3/PRECISION) - 1;
            end else if (symbol_valid && !valid_stage1 && !valid_stage2 && !valid_stage3) begin
                // Initialize on first valid input if pipeline is empty
                lower_bound <= 0;
                upper_bound <= {PRECISION{1'b1}};
            end
        end
    end
endmodule