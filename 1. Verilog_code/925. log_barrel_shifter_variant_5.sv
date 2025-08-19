//SystemVerilog
module log_barrel_shifter (
    input            clk,
    input            rst_n,
    input  [15:0]    data_i,
    input  [3:0]     shamt,
    input            valid_i,
    output           ready_o,
    output [15:0]    data_o,
    output           valid_o,
    input            ready_i
);
    // Intermediate pipeline stage registers and control signals
    reg [15:0] stage0_data, stage1_data, stage2_data, stage3_data, stage4_data;
    reg [3:0]  stage0_shamt, stage1_shamt, stage2_shamt, stage3_shamt;
    reg        stage0_valid, stage1_valid, stage2_valid, stage3_valid, stage4_valid;
    
    // Pipeline handshaking
    wire stage0_ready, stage1_ready, stage2_ready, stage3_ready, stage4_ready;
    
    // Implement backpressure through pipeline
    assign stage4_ready = ready_i || !stage4_valid;
    assign stage3_ready = stage4_ready || !stage3_valid;
    assign stage2_ready = stage3_ready || !stage2_valid;
    assign stage1_ready = stage2_ready || !stage1_valid;
    assign stage0_ready = stage1_ready || !stage0_valid;
    
    // Input handshaking
    assign ready_o = stage0_ready;
    
    // Output connection
    assign data_o = stage4_data;
    assign valid_o = stage4_valid;
    
    // Stage 0: Input register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage0_data <= 16'b0;
            stage0_shamt <= 4'b0;
            stage0_valid <= 1'b0;
        end else if (stage0_ready) begin
            if (valid_i) begin
                stage0_data <= data_i;
                stage0_shamt <= shamt;
                stage0_valid <= 1'b1;
            end else begin
                stage0_valid <= 1'b0;
            end
        end
    end
    
    // Stage 1: Shift by 0 or 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 16'b0;
            stage1_shamt <= 4'b0;
            stage1_valid <= 1'b0;
        end else if (stage1_ready) begin
            if (stage0_valid) begin
                stage1_data <= stage0_shamt[0] ? {stage0_data[14:0], 1'b0} : stage0_data;
                stage1_shamt <= stage0_shamt;
                stage1_valid <= 1'b1;
            end else begin
                stage1_valid <= 1'b0;
            end
        end
    end
    
    // Stage 2: Shift by 0 or 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= 16'b0;
            stage2_shamt <= 4'b0;
            stage2_valid <= 1'b0;
        end else if (stage2_ready) begin
            if (stage1_valid) begin
                stage2_data <= stage1_shamt[1] ? {stage1_data[13:0], 2'b0} : stage1_data;
                stage2_shamt <= stage1_shamt;
                stage2_valid <= 1'b1;
            end else begin
                stage2_valid <= 1'b0;
            end
        end
    end
    
    // Stage 3: Shift by 0 or 4
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_data <= 16'b0;
            stage3_shamt <= 4'b0;
            stage3_valid <= 1'b0;
        end else if (stage3_ready) begin
            if (stage2_valid) begin
                stage3_data <= stage2_shamt[2] ? {stage2_data[11:0], 4'b0} : stage2_data;
                stage3_shamt <= stage2_shamt;
                stage3_valid <= 1'b1;
            end else begin
                stage3_valid <= 1'b0;
            end
        end
    end
    
    // Stage 4: Shift by 0 or 8 (Final stage)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage4_data <= 16'b0;
            stage4_valid <= 1'b0;
        end else if (stage4_ready) begin
            if (stage3_valid) begin
                stage4_data <= stage3_shamt[3] ? {stage3_data[7:0], 8'b0} : stage3_data;
                stage4_valid <= 1'b1;
            end else begin
                stage4_valid <= 1'b0;
            end
        end
    end
endmodule