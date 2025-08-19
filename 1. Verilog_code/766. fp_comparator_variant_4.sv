//SystemVerilog
module fp_comparator(
    input clk,                 // Clock signal
    input rst_n,               // Active-low reset
    
    // Input interface - Valid-Ready protocol
    input [31:0] fp_a,         // IEEE 754 single precision format
    input [31:0] fp_b,         // IEEE 754 single precision format
    input        valid_in,     // Input data valid signal
    output       ready_in,     // Input ready signal
    
    // Output interface - Valid-Ready protocol
    output reg [3:0] result,   // {unordered, lt_result, gt_result, eq_result}
    output reg       valid_out, // Output valid signal
    input            ready_out  // Output ready signal
);
    // FSM states
    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg ready_in_reg;
    reg [31:0] fp_a_reg, fp_b_reg;
    
    // Extract sign, exponent, and mantissa fields
    wire a_sign = fp_a_reg[31];
    wire b_sign = fp_b_reg[31];
    wire [7:0] a_exp = fp_a_reg[30:23];
    wire [7:0] b_exp = fp_b_reg[30:23];
    wire [22:0] a_mant = fp_a_reg[22:0];
    wire [22:0] b_mant = fp_b_reg[22:0];
    
    // Efficient special case detection - combined equality checks
    wire a_is_zero = (a_exp == 8'h00) && (a_mant == 23'h0);
    wire b_is_zero = (b_exp == 8'h00) && (b_mant == 23'h0);
    wire both_zero = a_is_zero && b_is_zero;
    
    wire a_is_inf = (a_exp == 8'hFF) && (a_mant == 23'h0);
    wire b_is_inf = (b_exp == 8'hFF) && (b_mant == 23'h0);
    wire both_inf = a_is_inf && b_is_inf;
    
    wire a_is_nan = (a_exp == 8'hFF) && (|a_mant);
    wire b_is_nan = (b_exp == 8'hFF) && (|b_mant);
    wire any_nan = a_is_nan || b_is_nan;
    
    // Pre-compute common comparisons
    wire exact_equal = (fp_a_reg == fp_b_reg);
    wire sign_diff = a_sign ^ b_sign;
    wire a_larger_exp = a_exp > b_exp;
    wire exp_equal = (a_exp == b_exp);
    wire a_larger_mant = a_mant > b_mant;
    
    // Magnitude comparison (regardless of sign)
    wire a_mag_gt_b = a_larger_exp || (exp_equal && a_larger_mant);
    
    // Comparison results
    reg eq_result_comb, gt_result_comb, lt_result_comb, unordered_comb;
    
    // FSM for handshaking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            fp_a_reg <= 32'b0;
            fp_b_reg <= 32'b0;
            valid_out <= 1'b0;
            result <= 4'b0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    if (valid_in && ready_in_reg) begin
                        fp_a_reg <= fp_a;
                        fp_b_reg <= fp_b;
                    end
                    valid_out <= 1'b0;
                end
                
                PROCESSING: begin
                    result <= {unordered_comb, lt_result_comb, gt_result_comb, eq_result_comb};
                    valid_out <= 1'b1;
                end
                
                DONE: begin
                    if (ready_out) begin
                        valid_out <= 1'b0;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (valid_in && ready_in_reg) begin
                    next_state = PROCESSING;
                end
            end
            
            PROCESSING: begin
                next_state = DONE;
            end
            
            DONE: begin
                if (ready_out) begin
                    next_state = IDLE;
                end
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Input ready signal generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_in_reg <= 1'b1;
        end else begin
            if (state == IDLE && valid_in && ready_in_reg) begin
                ready_in_reg <= 1'b0;
            end else if (state == DONE && ready_out) begin
                ready_in_reg <= 1'b1;
            end
        end
    end
    
    assign ready_in = ready_in_reg;
    
    // Optimized comparison logic with priority encoding to reduce logic depth
    always @(*) begin
        // Default values - helps with better synthesis
        eq_result_comb = 1'b0;
        gt_result_comb = 1'b0;
        lt_result_comb = 1'b0;
        unordered_comb = 1'b0;
        
        // Priority 1: Handle NaN cases first (highest priority)
        if (any_nan) begin
            unordered_comb = 1'b1;
        end
        // Priority 2: Equality cases
        else if (exact_equal || both_zero) begin
            eq_result_comb = 1'b1;
        end
        // Priority 3: Handle sign differences (simplifies comparisons)
        else if (sign_diff) begin
            gt_result_comb = !a_sign;  // a positive, b negative
            lt_result_comb = a_sign;   // a negative, b positive
        end
        // Priority 4: Both infinity with same sign
        else if (both_inf) begin
            // Nothing to do - they are either equal (handled above)
            // or will be handled by sign difference (also handled above)
        end
        // Priority 5: Same sign - compare magnitudes
        else if (!a_sign) begin
            // Both positive - normal comparison
            gt_result_comb = a_mag_gt_b;
            lt_result_comb = !a_mag_gt_b;
        end
        else begin
            // Both negative - reversed comparison
            gt_result_comb = !a_mag_gt_b;
            lt_result_comb = a_mag_gt_b;
        end
    end
endmodule