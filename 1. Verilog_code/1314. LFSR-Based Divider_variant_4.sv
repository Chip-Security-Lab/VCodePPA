//SystemVerilog
module lfsr_divider (
    input wire i_clk,
    input wire i_rst,
    output wire o_clk_div
);
    // Stage 1 registers
    reg [2:0] lfsr_stage1;
    reg stage1_valid;
    
    // Stage 2 registers
    reg [4:0] lfsr_stage2;
    reg stage2_valid;
    
    // Pipeline registers for critical path cutting
    reg feedback_stage1_reg;
    reg [2:0] next_lfsr_stage1_reg;
    
    // Buffer registers for high fanout signal lfsr_stage2
    reg [4:0] lfsr_stage2_buf1;
    reg [4:0] lfsr_stage2_buf2;
    
    // Feedback calculation using buffered signals to reduce fanout
    wire feedback_stage1 = lfsr_stage2_buf1[4] ^ lfsr_stage2_buf1[2];
    
    // Register the feedback and next_lfsr values to cut critical path
    always @(posedge i_clk) begin
        if (i_rst) begin
            feedback_stage1_reg <= 1'b1;
            next_lfsr_stage1_reg <= 3'b111;
        end else begin
            feedback_stage1_reg <= feedback_stage1;
            next_lfsr_stage1_reg <= lfsr_stage2_buf2[2:0];
        end
    end
    
    // Buffer registers to reduce fanout of lfsr_stage2
    always @(posedge i_clk) begin
        lfsr_stage2_buf1 <= lfsr_stage2;
        lfsr_stage2_buf2 <= lfsr_stage2;
    end
    
    // Next state logic using registered values
    wire [4:0] next_lfsr_stage2 = i_rst ? 5'h1f : 
                                 {lfsr_stage2_buf1[3:0], feedback_stage1_reg};
    wire [2:0] next_lfsr_stage1 = i_rst ? 3'b111 : next_lfsr_stage1_reg;
    
    // Stage 1 pipeline registers
    always @(posedge i_clk) begin
        if (i_rst) begin
            lfsr_stage1 <= 3'b111;
            stage1_valid <= 1'b0;
        end else begin
            lfsr_stage1 <= next_lfsr_stage1;
            stage1_valid <= 1'b1;
        end
    end
    
    // Stage 2 pipeline registers
    always @(posedge i_clk) begin
        if (i_rst) begin
            lfsr_stage2 <= 5'h1f;
            stage2_valid <= 1'b0;
        end else begin
            if (stage1_valid) begin
                lfsr_stage2 <= next_lfsr_stage2;
                stage2_valid <= 1'b1;
            end
        end
    end
    
    // Output assignment - use registered value from buffer
    assign o_clk_div = stage2_valid ? lfsr_stage2_buf1[4] : 1'b0;
    
endmodule