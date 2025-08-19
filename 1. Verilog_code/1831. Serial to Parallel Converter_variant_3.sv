//SystemVerilog
module serial2parallel_converter #(
    parameter WORD_SIZE = 8
) (
    input  wire clk,
    input  wire n_reset,
    input  wire serial_in,
    input  wire load_en,
    output wire [WORD_SIZE-1:0] parallel_out,
    output wire conversion_done
);
    // Stage 1 - Input processing
    reg stage1_valid;
    reg stage1_serial_bit;
    reg [$clog2(WORD_SIZE)-1:0] stage1_bit_counter;
    
    // Stage 2 - Shift register operation
    reg stage2_valid;
    reg [WORD_SIZE-1:0] stage2_shift_reg;
    reg [$clog2(WORD_SIZE)-1:0] stage2_bit_counter;
    
    // Stage 3 - Output preparation
    reg stage3_valid;
    reg [WORD_SIZE-1:0] stage3_shift_reg;
    reg stage3_done_flag;
    
    // Signals for parallel prefix subtractor
    wire [WORD_SIZE-1:0] subtractor_result;
    reg [WORD_SIZE-1:0] adjustment_value;
    
    // Output assignments
    assign parallel_out = stage3_shift_reg;
    assign conversion_done = stage3_done_flag;
    
    // Parallel Prefix Subtractor implementation
    // Generate propagate (P) and generate (G) signals
    wire [WORD_SIZE-1:0] p, g;
    wire [WORD_SIZE-1:0] minuend, subtrahend, diff;
    
    // Use current shift register as minuend and a fixed adjustment value as subtrahend
    assign minuend = stage2_shift_reg;
    
    // Always set adjustment value based on bit counter
    always @(posedge clk or negedge n_reset) begin
        if (!n_reset) begin
            adjustment_value <= {WORD_SIZE{1'b0}};
        end else if (stage2_valid) begin
            adjustment_value <= WORD_SIZE - stage2_bit_counter - 1'b1;
        end
    end
    
    assign subtrahend = adjustment_value;
    
    // Generate P and G signals for each bit position
    assign p = minuend ^ subtrahend;
    assign g = minuend & ~subtrahend;
    
    // Parallel prefix computation for carry
    wire [WORD_SIZE:0] carry;
    assign carry[0] = 1'b0; // No initial borrow
    
    // Level 1 prefix computation
    wire [WORD_SIZE-1:0] p_l1, g_l1;
    generate
        for (genvar i = 0; i < WORD_SIZE/2; i = i + 1) begin
            // Compute prefix for pairs (2i, 2i+1)
            assign p_l1[2*i] = p[2*i];
            assign g_l1[2*i] = g[2*i];
            
            assign p_l1[2*i+1] = p[2*i+1] & p[2*i];
            assign g_l1[2*i+1] = g[2*i+1] | (p[2*i+1] & g[2*i]);
        end
    endgenerate
    
    // Level 2 prefix computation
    wire [WORD_SIZE-1:0] p_l2, g_l2;
    generate
        for (genvar i = 0; i < WORD_SIZE/4; i = i + 1) begin
            // Compute prefix for groups of 4
            for (genvar j = 0; j < 2; j = j + 1) begin
                assign p_l2[4*i+j] = p_l1[4*i+j];
                assign g_l2[4*i+j] = g_l1[4*i+j];
            end
            
            for (genvar j = 2; j < 4; j = j + 1) begin
                assign p_l2[4*i+j] = p_l1[4*i+j] & p_l1[4*i+1];
                assign g_l2[4*i+j] = g_l1[4*i+j] | (p_l1[4*i+j] & g_l1[4*i+1]);
            end
        end
    endgenerate
    
    // Level 3 prefix computation (final for 8-bit)
    wire [WORD_SIZE-1:0] p_l3, g_l3;
    generate
        for (genvar i = 0; i < 4; i = i + 1) begin
            assign p_l3[i] = p_l2[i];
            assign g_l3[i] = g_l2[i];
        end
        
        for (genvar i = 4; i < 8; i = i + 1) begin
            assign p_l3[i] = p_l2[i] & p_l2[3];
            assign g_l3[i] = g_l2[i] | (p_l2[i] & g_l2[3]);
        end
    endgenerate
    
    // Compute carries
    generate
        for (genvar i = 0; i < WORD_SIZE; i = i + 1) begin
            assign carry[i+1] = g_l3[i] | (p_l3[i] & carry[i]);
        end
    endgenerate
    
    // Compute difference
    assign diff = p ^ carry[WORD_SIZE-1:0];
    
    // Result of subtraction available for potential use
    assign subtractor_result = diff;
    
    // Stage 1: Input capture and counter management
    always @(posedge clk or negedge n_reset) begin
        if (!n_reset) begin
            stage1_valid <= 1'b0;
            stage1_serial_bit <= 1'b0;
            stage1_bit_counter <= {$clog2(WORD_SIZE){1'b0}};
        end else begin
            stage1_valid <= load_en;
            if (load_en) begin
                stage1_serial_bit <= serial_in;
                if (stage2_bit_counter == WORD_SIZE-1) begin
                    stage1_bit_counter <= {$clog2(WORD_SIZE){1'b0}};
                end else begin
                    stage1_bit_counter <= stage2_bit_counter + 1'b1;
                end
            end
        end
    end
    
    // Stage 2: Shift register operation
    always @(posedge clk or negedge n_reset) begin
        if (!n_reset) begin
            stage2_valid <= 1'b0;
            stage2_shift_reg <= {WORD_SIZE{1'b0}};
            stage2_bit_counter <= {$clog2(WORD_SIZE){1'b0}};
        end else begin
            stage2_valid <= stage1_valid;
            stage2_bit_counter <= stage1_bit_counter;
            
            if (stage1_valid) begin
                stage2_shift_reg <= {stage2_shift_reg[WORD_SIZE-2:0], stage1_serial_bit};
            end
        end
    end
    
    // Stage 3: Output preparation
    always @(posedge clk or negedge n_reset) begin
        if (!n_reset) begin
            stage3_valid <= 1'b0;
            stage3_shift_reg <= {WORD_SIZE{1'b0}};
            stage3_done_flag <= 1'b0;
        end else begin
            stage3_valid <= stage2_valid;
            
            // 将条件运算符转换为if-else结构
            if (stage2_bit_counter == WORD_SIZE-1) begin
                stage3_shift_reg <= subtractor_result;
            end else begin
                stage3_shift_reg <= stage2_shift_reg;
            end
            
            if (stage2_valid && (stage2_bit_counter == WORD_SIZE-1)) begin
                stage3_done_flag <= 1'b1;
            end else begin
                stage3_done_flag <= 1'b0;
            end
        end
    end
endmodule