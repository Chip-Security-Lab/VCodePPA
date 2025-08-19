//SystemVerilog
module shift_ff (
    input  wire clk, 
    input  wire rstn, 
    input  wire sin,
    output wire q
);

    // Pipeline stage registers
    reg stage1_data, stage2_data, stage3_data, stage4_data;
    
    // Pipeline valid signals to track data flow
    reg stage1_valid, stage2_valid, stage3_valid, stage4_valid;
    
    // ---------- Stage 1: Input registration ----------
    // Data path
    always @(posedge clk) begin
        if (!rstn)
            stage1_data <= 1'b0;
        else
            stage1_data <= sin;
    end
    
    // Control path
    always @(posedge clk) begin
        if (!rstn)
            stage1_valid <= 1'b0;
        else
            stage1_valid <= 1'b1;
    end
    
    // ---------- Stage 2: First pipeline stage ----------
    // Data path
    always @(posedge clk) begin
        if (!rstn)
            stage2_data <= 1'b0;
        else
            stage2_data <= stage1_data;
    end
    
    // Control path
    always @(posedge clk) begin
        if (!rstn)
            stage2_valid <= 1'b0;
        else
            stage2_valid <= stage1_valid;
    end
    
    // ---------- Stage 3: Second pipeline stage ----------
    // Data path
    always @(posedge clk) begin
        if (!rstn)
            stage3_data <= 1'b0;
        else
            stage3_data <= stage2_data;
    end
    
    // Control path
    always @(posedge clk) begin
        if (!rstn)
            stage3_valid <= 1'b0;
        else
            stage3_valid <= stage2_valid;
    end
    
    // ---------- Stage 4: Output stage ----------
    // Data path
    always @(posedge clk) begin
        if (!rstn)
            stage4_data <= 1'b0;
        else
            stage4_data <= stage3_data;
    end
    
    // Control path
    always @(posedge clk) begin
        if (!rstn)
            stage4_valid <= 1'b0;
        else
            stage4_valid <= stage3_valid;
    end
    
    // Output assignment
    assign q = stage4_data;
    
endmodule