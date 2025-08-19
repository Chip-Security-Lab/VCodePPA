//SystemVerilog
module async_divider (
    input wire master_clk,
    input wire reset_n,  // Added reset for proper initialization
    output wire div2_clk,
    output wire div4_clk,
    output wire div8_clk,
    output wire div16_clk // Added additional division stage
);
    // Divider chain registers
    reg [3:0] div_chain;  // Extended to support div16
    
    // Multi-stage buffering to reduce critical path and improve timing
    // Stage 1 buffers
    reg div_chain0_buf1, div_chain0_buf2, div_chain0_buf3;
    reg div_chain1_buf1, div_chain1_buf2, div_chain1_buf3;
    reg div_chain2_buf1, div_chain2_buf2;
    
    // Stage 2 buffers - additional pipeline stage
    reg div_chain0_stage2_buf1, div_chain0_stage2_buf2;
    reg div_chain1_stage2_buf1, div_chain1_stage2_buf2;
    reg div_chain2_stage2_buf;
    
    // Output registers for improved timing
    reg div2_clk_reg, div4_clk_reg, div8_clk_reg, div16_clk_reg;

    // First divider stage with reset
    always @(posedge master_clk or negedge reset_n) begin
        if (!reset_n)
            div_chain[0] <= 1'b0;
        else
            div_chain[0] <= ~div_chain[0];
    end
    
    // Stage 1 buffer registers for div_chain[0] to reduce fan-out
    always @(posedge master_clk or negedge reset_n) begin
        if (!reset_n) begin
            div_chain0_buf1 <= 1'b0;
            div_chain0_buf2 <= 1'b0;
            div_chain0_buf3 <= 1'b0;
        end else begin
            div_chain0_buf1 <= div_chain[0];
            div_chain0_buf2 <= div_chain[0];
            div_chain0_buf3 <= div_chain[0];
        end
    end
    
    // Stage 2 buffer registers - additional pipeline stage
    always @(posedge master_clk or negedge reset_n) begin
        if (!reset_n) begin
            div_chain0_stage2_buf1 <= 1'b0;
            div_chain0_stage2_buf2 <= 1'b0;
        end else begin
            div_chain0_stage2_buf1 <= div_chain0_buf1;
            div_chain0_stage2_buf2 <= div_chain0_buf2;
        end
    end
    
    // Second divider stage using buffered signal with reset
    always @(posedge div_chain0_stage2_buf1 or negedge reset_n) begin
        if (!reset_n)
            div_chain[1] <= 1'b0;
        else
            div_chain[1] <= ~div_chain[1];
    end
    
    // Stage 1 buffer registers for div_chain[1]
    always @(posedge master_clk or negedge reset_n) begin
        if (!reset_n) begin
            div_chain1_buf1 <= 1'b0;
            div_chain1_buf2 <= 1'b0;
            div_chain1_buf3 <= 1'b0;
        end else begin
            div_chain1_buf1 <= div_chain[1];
            div_chain1_buf2 <= div_chain[1];
            div_chain1_buf3 <= div_chain[1];
        end
    end
    
    // Stage 2 buffer registers - additional pipeline stage
    always @(posedge master_clk or negedge reset_n) begin
        if (!reset_n) begin
            div_chain1_stage2_buf1 <= 1'b0;
            div_chain1_stage2_buf2 <= 1'b0;
        end else begin
            div_chain1_stage2_buf1 <= div_chain1_buf1;
            div_chain1_stage2_buf2 <= div_chain1_buf2;
        end
    end
    
    // Third divider stage using buffered signal with reset
    always @(posedge div_chain1_stage2_buf1 or negedge reset_n) begin
        if (!reset_n)
            div_chain[2] <= 1'b0;
        else
            div_chain[2] <= ~div_chain[2];
    end
    
    // Stage 1 buffer registers for div_chain[2]
    always @(posedge master_clk or negedge reset_n) begin
        if (!reset_n) begin
            div_chain2_buf1 <= 1'b0;
            div_chain2_buf2 <= 1'b0;
        end else begin
            div_chain2_buf1 <= div_chain[2];
            div_chain2_buf2 <= div_chain[2];
        end
    end
    
    // Stage 2 buffer registers - additional pipeline stage
    always @(posedge master_clk or negedge reset_n) begin
        if (!reset_n) begin
            div_chain2_stage2_buf <= 1'b0;
        end else begin
            div_chain2_stage2_buf <= div_chain2_buf1;
        end
    end
    
    // Fourth divider stage using buffered signal with reset (new addition)
    always @(posedge div_chain2_stage2_buf or negedge reset_n) begin
        if (!reset_n)
            div_chain[3] <= 1'b0;
        else
            div_chain[3] <= ~div_chain[3];
    end
    
    // Output registers for improved timing
    always @(posedge master_clk or negedge reset_n) begin
        if (!reset_n) begin
            div2_clk_reg <= 1'b0;
            div4_clk_reg <= 1'b0;
            div8_clk_reg <= 1'b0;
            div16_clk_reg <= 1'b0;
        end else begin
            div2_clk_reg <= div_chain0_stage2_buf2;
            div4_clk_reg <= div_chain1_stage2_buf2;
            div8_clk_reg <= div_chain2_buf2;
            div16_clk_reg <= div_chain[3];
        end
    end
    
    // Output assignments using registered outputs for improved timing
    assign div2_clk = div2_clk_reg;
    assign div4_clk = div4_clk_reg;
    assign div8_clk = div8_clk_reg;
    assign div16_clk = div16_clk_reg;
endmodule