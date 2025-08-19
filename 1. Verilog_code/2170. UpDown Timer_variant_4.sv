//SystemVerilog
// SystemVerilog
///////////////////////////////////////////////////////////////
// Module: updown_timer
// Description: Pipelined up/down counter with load capability and overflow/underflow detection
///////////////////////////////////////////////////////////////
module updown_timer #(
    parameter WIDTH = 16
)(
    // Clock and control signals
    input                   clk,        // System clock
    input                   rst_n,      // Active-low reset
    input                   en,         // Counter enable
    input                   up_down,    // Direction control (1=up, 0=down)
    
    // Load interface
    input [WIDTH-1:0]       load_val,   // Value to load
    input                   load_en,    // Load enable
    
    // Outputs
    output reg [WIDTH-1:0]  count,      // Current count value
    output reg              overflow,   // Overflow indicator
    output reg              underflow   // Underflow indicator
);
    // Pipeline stage 1: Input registration and control signals
    reg                     en_stage1;
    reg                     up_down_stage1;
    reg                     load_en_stage1;
    reg [WIDTH-1:0]         load_val_stage1;
    reg                     valid_stage1;
    
    // Pipeline stage 2: Next count computation
    reg [WIDTH-1:0]         next_count_stage2;
    reg                     en_stage2;
    reg                     up_down_stage2;
    reg                     valid_stage2;
    // Pre-computed values for increment/decrement operations
    reg [WIDTH-1:0]         count_plus_one;
    reg [WIDTH-1:0]         count_minus_one;
    
    // Pipeline stage 3: Count register update
    reg [WIDTH-1:0]         count_stage3;
    reg                     en_stage3;
    reg                     up_down_stage3;
    reg                     valid_stage3;
    
    // Pipeline stage 4: Boundary condition detection
    reg                     count_at_max_stage4;
    reg                     count_at_zero_stage4;
    reg                     en_stage4;
    reg                     up_down_stage4;
    reg                     valid_stage4;
    
    // Pre-compute for boundary detection
    wire is_max = &count_stage3;
    wire is_zero = ~|count_stage3;
    
    // Stage 1: Register inputs
    always @(posedge clk) begin
        if (!rst_n) begin
            en_stage1       <= 1'b0;
            up_down_stage1  <= 1'b0;
            load_en_stage1  <= 1'b0;
            load_val_stage1 <= {WIDTH{1'b0}};
            valid_stage1    <= 1'b0;
        end else begin
            en_stage1       <= en;
            up_down_stage1  <= up_down;
            load_en_stage1  <= load_en;
            load_val_stage1 <= load_val;
            valid_stage1    <= 1'b1;
        end
    end
    
    // Pre-compute possible next values to reduce critical path
    always @(posedge clk) begin
        if (!rst_n) begin
            count_plus_one <= {WIDTH{1'b0}};
            count_minus_one <= {WIDTH{1'b0}};
        end else begin
            count_plus_one <= count + 1'b1;
            count_minus_one <= count - 1'b1;
        end
    end
    
    // Stage 2: Next count value computation - parallelized paths
    always @(posedge clk) begin
        if (!rst_n) begin
            next_count_stage2 <= {WIDTH{1'b0}};
            en_stage2         <= 1'b0;
            up_down_stage2    <= 1'b0;
            valid_stage2      <= 1'b0;
        end else if (valid_stage1) begin
            // Prioritize load operation - separate path
            if (load_en_stage1) begin
                next_count_stage2 <= load_val_stage1;
            end 
            // Increment/decrement - use pre-computed values
            else if (en_stage1) begin
                next_count_stage2 <= up_down_stage1 ? count_plus_one : count_minus_one;
            end 
            // Hold current count - separate path
            else begin
                next_count_stage2 <= count;
            end
            
            en_stage2       <= en_stage1;
            up_down_stage2  <= up_down_stage1;
            valid_stage2    <= 1'b1;
        end else begin
            valid_stage2    <= 1'b0;
        end
    end
    
    // Stage 3: Update count register
    always @(posedge clk) begin
        if (!rst_n) begin
            count_stage3    <= {WIDTH{1'b0}};
            en_stage3       <= 1'b0;
            up_down_stage3  <= 1'b0;
            valid_stage3    <= 1'b0;
        end else if (valid_stage2) begin
            count_stage3    <= next_count_stage2;
            en_stage3       <= en_stage2;
            up_down_stage3  <= up_down_stage2;
            valid_stage3    <= 1'b1;
        end else begin
            valid_stage3    <= 1'b0;
        end
    end
    
    // Stage 4: Boundary condition detection - use pre-computed boundary tests
    always @(posedge clk) begin
        if (!rst_n) begin
            count_at_max_stage4  <= 1'b0;
            count_at_zero_stage4 <= 1'b1;
            en_stage4            <= 1'b0;
            up_down_stage4       <= 1'b0;
            valid_stage4         <= 1'b0;
        end else if (valid_stage3) begin
            count_at_max_stage4  <= is_max;
            count_at_zero_stage4 <= is_zero;
            en_stage4            <= en_stage3;
            up_down_stage4       <= up_down_stage3;
            valid_stage4         <= 1'b1;
        end else begin
            valid_stage4         <= 1'b0;
        end
    end
    
    // Pre-compute flag conditions to reduce final stage complexity
    wire overflow_condition = en_stage4 & up_down_stage4 & count_at_max_stage4;
    wire underflow_condition = en_stage4 & ~up_down_stage4 & count_at_zero_stage4;
    
    // Stage 5: Output generation
    always @(posedge clk) begin
        if (!rst_n) begin
            count     <= {WIDTH{1'b0}};
            overflow  <= 1'b0;
            underflow <= 1'b0;
        end else if (valid_stage4) begin
            count     <= count_stage3;
            overflow  <= overflow_condition;
            underflow <= underflow_condition;
        end
    end

endmodule