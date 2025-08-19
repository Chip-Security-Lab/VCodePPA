//SystemVerilog
// SystemVerilog
module fractional_n_div #(
    parameter INT_DIV = 4,
    parameter FRAC_DIV = 3,
    parameter FRAC_BITS = 4
) (
    input clk_src, reset_n,
    output reg clk_out
);
    // Stage 1: Counter and accumulator logic
    reg [3:0] int_counter_stage1;
    reg [FRAC_BITS-1:0] frac_acc_stage1;
    reg [FRAC_BITS-1:0] frac_acc_next_stage1;
    reg counter_reset_stage1;
    reg frac_overflow_stage1;
    
    // Borrow subtractor signals
    reg [FRAC_BITS:0] borrow;
    reg [FRAC_BITS-1:0] subtraction_result;
    
    // Stage 2: Clock toggle decision
    reg [3:0] int_counter_stage2;
    reg [FRAC_BITS-1:0] frac_acc_stage2;
    reg counter_reset_stage2;
    reg toggle_clk_stage2;
    
    // Stage 3: Clock output generation
    reg toggle_clk_stage3;
    
    // Stage 1: Compute next values and overflow condition using borrow subtractor
    always @(posedge clk_src or negedge reset_n) begin
        if (!reset_n) begin
            int_counter_stage1 <= 0;
            frac_acc_stage1 <= 0;
            frac_overflow_stage1 <= 0;
            counter_reset_stage1 <= 0;
            frac_acc_next_stage1 <= 0;
            borrow <= 0;
            subtraction_result <= 0;
        end else begin
            // Implement borrow subtractor for checking overflow
            // Check if (frac_acc_stage1 + FRAC_DIV) >= (1 << FRAC_BITS)
            // This is equivalent to checking if ((1 << FRAC_BITS) - (frac_acc_stage1 + FRAC_DIV)) generates a borrow
            
            // Initialize borrow bits
            borrow[0] = ((1 << FRAC_BITS) & 1) < ((frac_acc_stage1 + FRAC_DIV) & 1);
            
            // 4-bit borrow subtractor implementation
            // For each bit, compute result and propagate borrow
            for (integer i = 1; i <= FRAC_BITS; i = i + 1) begin
                borrow[i] = (((1 << FRAC_BITS) >> i) & 1) < (((frac_acc_stage1 + FRAC_DIV) >> i) & 1) || 
                           ((((1 << FRAC_BITS) >> i) & 1) == (((frac_acc_stage1 + FRAC_DIV) >> i) & 1) && borrow[i-1]);
                           
                subtraction_result[i-1] = (((1 << FRAC_BITS) >> (i-1)) & 1) ^ (((frac_acc_stage1 + FRAC_DIV) >> (i-1)) & 1) ^ borrow[i-1];
            end
            
            // Determine overflow based on borrow out
            frac_overflow_stage1 <= borrow[FRAC_BITS];
            
            // Determine if counter should reset
            counter_reset_stage1 <= (int_counter_stage1 == 
                                    (borrow[FRAC_BITS] ? INT_DIV : INT_DIV-1) - 1);
            
            // Calculate next fractional accumulator value
            // Using borrow subtractor to compute: frac_acc_stage1 + FRAC_DIV - (overflow ? (1 << FRAC_BITS) : 0)
            if (borrow[FRAC_BITS]) begin
                // If overflow, subtract (1 << FRAC_BITS)
                frac_acc_next_stage1 <= frac_acc_stage1 + FRAC_DIV - (1 << FRAC_BITS);
            end else begin
                frac_acc_next_stage1 <= frac_acc_stage1 + FRAC_DIV;
            end
            
            // Update counter
            if (counter_reset_stage1)
                int_counter_stage1 <= 0;
            else
                int_counter_stage1 <= int_counter_stage1 + 1;
        end
    end
    
    // Stage 2: Update accumulator and prepare for clock toggle
    always @(posedge clk_src or negedge reset_n) begin
        if (!reset_n) begin
            int_counter_stage2 <= 0;
            frac_acc_stage2 <= 0;
            counter_reset_stage2 <= 0;
            toggle_clk_stage2 <= 0;
        end else begin
            int_counter_stage2 <= int_counter_stage1;
            counter_reset_stage2 <= counter_reset_stage1;
            
            // Update accumulator when counter resets
            if (counter_reset_stage1)
                frac_acc_stage2 <= frac_acc_next_stage1;
            else
                frac_acc_stage2 <= frac_acc_stage1;
            
            // Signal to toggle clock in next stage
            toggle_clk_stage2 <= counter_reset_stage1;
        end
    end
    
    // Feedback path for accumulator
    always @(posedge clk_src) begin
        frac_acc_stage1 <= frac_acc_stage2;
    end
    
    // Stage 3: Generate clock output
    always @(posedge clk_src or negedge reset_n) begin
        if (!reset_n) begin
            toggle_clk_stage3 <= 0;
            clk_out <= 0;
        end else begin
            toggle_clk_stage3 <= toggle_clk_stage2;
            
            // Toggle clock output when signaled
            if (toggle_clk_stage3)
                clk_out <= ~clk_out;
        end
    end
endmodule