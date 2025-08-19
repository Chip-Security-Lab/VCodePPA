//SystemVerilog
//-----------------------------------------------------------------------------
// Top Module - Arithmetic Encoder with Improved Pipeline Structure
//-----------------------------------------------------------------------------
module arithmetic_encoder #(
    parameter PRECISION = 16
)(
    input                       clk,
    input                       rst,
    input                       symbol_valid,
    input              [7:0]    symbol,
    output                      code_valid,
    output     [PRECISION-1:0]  lower_bound,
    output     [PRECISION-1:0]  upper_bound
);
    // Pipeline stage signals
    reg                      symbol_valid_r;
    reg              [7:0]   symbol_r;
    reg              [1:0]   symbol_msb_r;
    
    // Probability model signals
    wire [PRECISION-1:0]     prob_low, prob_high;
    reg  [PRECISION-1:0]     prob_low_r, prob_high_r;
    
    // Range calculation signals
    wire [PRECISION-1:0]     current_range;
    reg  [PRECISION-1:0]     range_r;
    
    // Bound calculation signals
    wire [2*PRECISION-1:0]   scaled_low, scaled_high;
    wire [PRECISION-1:0]     new_lower, new_upper;
    
    // Valid signal propagation
    reg                      stage1_valid, stage2_valid;
    
    //-------------------------------------------------------------------------
    // Stage 1: Input Registration and Probability Lookup
    //-------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            symbol_valid_r <= 1'b0;
            symbol_r <= 8'h0;
            symbol_msb_r <= 2'b00;
        end else begin
            symbol_valid_r <= symbol_valid;
            symbol_r <= symbol;
            symbol_msb_r <= symbol[7:6];
        end
    end
    
    // Probability table lookup module instantiation
    probability_model #(
        .PRECISION(PRECISION)
    ) prob_model_inst (
        .symbol_msb   (symbol_msb_r),
        .prob_low     (prob_low),
        .prob_high    (prob_high)
    );
    
    //-------------------------------------------------------------------------
    // Stage 2: Range Calculation and Probability Registration
    //-------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage1_valid <= 1'b0;
            prob_low_r <= {PRECISION{1'b0}};
            prob_high_r <= {PRECISION{1'b0}};
        end else begin
            stage1_valid <= symbol_valid_r;
            prob_low_r <= prob_low;
            prob_high_r <= prob_high;
        end
    end
    
    // Range calculation module instantiation
    range_calculator #(
        .PRECISION(PRECISION)
    ) range_calc_inst (
        .current_upper (upper_bound),
        .current_lower (lower_bound),
        .range         (current_range)
    );
    
    //-------------------------------------------------------------------------
    // Stage 3: Scaling and Bound Update Preparation
    //-------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage2_valid <= 1'b0;
            range_r <= {PRECISION{1'b0}};
        end else begin
            stage2_valid <= stage1_valid;
            range_r <= current_range;
        end
    end
    
    // Pipeline scaled probability calculations
    assign scaled_low = range_r * prob_low_r;
    assign scaled_high = range_r * prob_high_r;
    
    // Calculate new bounds with proper fixed-point scaling
    assign new_lower = scaled_low >> PRECISION;
    assign new_upper = (scaled_high >> PRECISION) - 1'b1;
    
    //-------------------------------------------------------------------------
    // Bound Update Controller - Final stage for bounds update
    //-------------------------------------------------------------------------
    bound_update_controller #(
        .PRECISION(PRECISION)
    ) bound_ctrl_inst (
        .clk           (clk),
        .rst           (rst),
        .update_valid  (stage2_valid),
        .new_lower     (new_lower),
        .new_upper     (new_upper),
        .lower_bound   (lower_bound),
        .upper_bound   (upper_bound),
        .code_valid    (code_valid)
    );
    
endmodule

//-----------------------------------------------------------------------------
// Probability Model - Handles probability table and lookups
//-----------------------------------------------------------------------------
module probability_model #(
    parameter PRECISION = 16
)(
    input      [1:0]            symbol_msb,
    output reg [PRECISION-1:0]  prob_low,
    output reg [PRECISION-1:0]  prob_high
);
    // Probability table definition - distributed ROM style implementation
    reg [PRECISION-1:0] prob_table [0:3];
    
    // Initialize probability table
    initial begin
        prob_table[0] = 0;                   // Start
        prob_table[1] = PRECISION/4;         // 25%
        prob_table[2] = PRECISION/2;         // 50%
        prob_table[3] = (3*PRECISION)/4;     // 75%
    end
    
    // Simple table lookup logic optimized for ROM inference
    always @(*) begin
        prob_low  = prob_table[symbol_msb];
        prob_high = prob_table[symbol_msb+1];
    end
    
endmodule

//-----------------------------------------------------------------------------
// Range Calculator - Calculates the current range with optional pipelining
//-----------------------------------------------------------------------------
module range_calculator #(
    parameter PRECISION = 16
)(
    input  [PRECISION-1:0] current_upper,
    input  [PRECISION-1:0] current_lower,
    output [PRECISION-1:0] range
);
    // Calculate range = upper_bound - lower_bound + 1
    // Simplified arithmetic path with reduced logic depth
    assign range = current_upper - current_lower + 1'b1;
    
endmodule

//-----------------------------------------------------------------------------
// Bound Update Controller - Updates bounds with cleaner pipeline structure
//-----------------------------------------------------------------------------
module bound_update_controller #(
    parameter PRECISION = 16
)(
    input                       clk,
    input                       rst,
    input                       update_valid,
    input      [PRECISION-1:0]  new_lower,
    input      [PRECISION-1:0]  new_upper,
    output reg [PRECISION-1:0]  lower_bound,
    output reg [PRECISION-1:0]  upper_bound,
    output reg                  code_valid
);
    // State management for bound updates
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lower_bound <= {PRECISION{1'b0}};           // All 0's
            upper_bound <= {PRECISION{1'b1}};           // All 1's
            code_valid  <= 1'b0;
        end else if (update_valid) begin
            // Clean update path with pre-calculated values
            lower_bound <= lower_bound + new_lower;
            upper_bound <= lower_bound + new_upper;
            code_valid  <= 1'b1;
        end else begin
            code_valid  <= 1'b0;
        end
    end
    
endmodule