//SystemVerilog
module glitch_filter_rst_sync (
    input  wire clk,
    input  wire async_rst_n,
    output wire filtered_rst_n
);
    // Main shift register with increased pipeline depth
    reg [1:0] shift_reg_stage1;
    reg [1:0] shift_reg_stage2;
    
    // Buffered copies with increased pipeline stages
    reg [1:0] shift_reg_buf1_stage1;
    reg [1:0] shift_reg_buf1_stage2;
    reg [1:0] shift_reg_buf2_stage1;
    reg [1:0] shift_reg_buf2_stage2;
    
    // Intermediate comparison signals
    reg shift_reg_all_ones_stage1;
    reg shift_reg_all_zeros_stage1;
    
    // Output register with pipeline stages
    reg filtered_stage1;
    reg filtered_stage2;
    
    // Stage 1 shift register logic - first half
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            shift_reg_stage1 <= 2'b00;
        else
            shift_reg_stage1 <= {shift_reg_stage1[0], 1'b1};
    end
    
    // Stage 2 shift register logic - second half
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            shift_reg_stage2 <= 2'b00;
        else
            shift_reg_stage2 <= {shift_reg_stage2[0], shift_reg_stage1[1]};
    end
    
    // Buffer registers stage 1 - first half
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            shift_reg_buf1_stage1 <= 2'b00;
            shift_reg_buf2_stage1 <= 2'b00;
        end
        else begin
            shift_reg_buf1_stage1 <= shift_reg_stage1;
            shift_reg_buf2_stage1 <= shift_reg_stage1;
        end
    end
    
    // Buffer registers stage 2 - second half
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            shift_reg_buf1_stage2 <= 2'b00;
            shift_reg_buf2_stage2 <= 2'b00;
        end
        else begin
            shift_reg_buf1_stage2 <= shift_reg_stage2;
            shift_reg_buf2_stage2 <= shift_reg_stage2;
        end
    end
    
    // Pre-compute comparison results in stage 1
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            shift_reg_all_ones_stage1 <= 1'b0;
            shift_reg_all_zeros_stage1 <= 1'b0;
        end
        else begin
            shift_reg_all_ones_stage1 <= 
                (shift_reg_buf1_stage1 == 2'b11) && (shift_reg_buf1_stage2 == 2'b11);
            shift_reg_all_zeros_stage1 <= 
                (shift_reg_buf2_stage1 == 2'b00) && (shift_reg_buf2_stage2 == 2'b00);
        end
    end
    
    // Use pre-computed results in stage 1
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            filtered_stage1 <= 1'b0;
        else if (shift_reg_all_ones_stage1)
            filtered_stage1 <= 1'b1;
        else if (shift_reg_all_zeros_stage1)
            filtered_stage1 <= 1'b0;
    end
    
    // Pipeline register for the final output in stage 2
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            filtered_stage2 <= 1'b0;
        else
            filtered_stage2 <= filtered_stage1;
    end
    
    assign filtered_rst_n = filtered_stage2;
endmodule