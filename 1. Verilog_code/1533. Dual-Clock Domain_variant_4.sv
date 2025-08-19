//SystemVerilog
// IEEE 1364-2005 Verilog
module dual_clk_shadow_reg #(
    parameter WIDTH = 8
)(
    // Primary domain
    input wire clk_pri,
    input wire rst_n_pri,
    input wire [WIDTH-1:0] data_pri,
    input wire capture,
    
    // Shadow domain
    input wire clk_shd,
    input wire rst_n_shd,
    output reg [WIDTH-1:0] shadow_data
);
    // Primary domain registers with pipeline stages
    reg [WIDTH-1:0] pri_reg_stage1, pri_reg_stage2;
    reg cap_flag_stage1, cap_flag_stage2;
    
    // Shadow domain registers and synchronized signals with deeper pipeline
    reg cap_meta_stage1, cap_meta_stage2;
    reg cap_detect_stage1, cap_detect_stage2;
    reg cap_sync_stage1, cap_sync_stage2;
    
    // Primary domain feedback synchronizer with pipeline
    reg cap_sync_meta_stage1, cap_sync_meta_stage2;
    reg cap_sync_feedback_stage1, cap_sync_feedback_stage2;
    
    // Primary register pipeline - stage 1: data sampling and initial capture flag
    always @(posedge clk_pri or negedge rst_n_pri) begin
        if (!rst_n_pri) begin
            pri_reg_stage1 <= 0;
            cap_flag_stage1 <= 0;
        end else begin
            pri_reg_stage1 <= data_pri;
            cap_flag_stage1 <= capture ? 1'b1 : (cap_sync_feedback_stage2 ? 1'b0 : cap_flag_stage2);
        end
    end
    
    // Primary register pipeline - stage 2: data and flag propagation
    always @(posedge clk_pri or negedge rst_n_pri) begin
        if (!rst_n_pri) begin
            pri_reg_stage2 <= 0;
            cap_flag_stage2 <= 0;
        end else begin
            pri_reg_stage2 <= pri_reg_stage1;
            cap_flag_stage2 <= cap_flag_stage1;
        end
    end
    
    // Synchronizer for feedback path from shadow to primary domain - stage 1
    always @(posedge clk_pri or negedge rst_n_pri) begin
        if (!rst_n_pri) begin
            cap_sync_meta_stage1 <= 0;
            cap_sync_feedback_stage1 <= 0;
        end else begin
            cap_sync_meta_stage1 <= cap_sync_stage2;
            cap_sync_feedback_stage1 <= cap_sync_meta_stage2;
        end
    end
    
    // Synchronizer for feedback path from shadow to primary domain - stage 2
    always @(posedge clk_pri or negedge rst_n_pri) begin
        if (!rst_n_pri) begin
            cap_sync_meta_stage2 <= 0;
            cap_sync_feedback_stage2 <= 0;
        end else begin
            cap_sync_meta_stage2 <= cap_sync_meta_stage1;
            cap_sync_feedback_stage2 <= cap_sync_feedback_stage1;
        end
    end
    
    // Shadow domain clock crossing - stage 1: initial metastability resolution
    always @(posedge clk_shd or negedge rst_n_shd) begin
        if (!rst_n_shd) begin
            cap_meta_stage1 <= 0;
            cap_detect_stage1 <= 0;
        end else begin
            cap_meta_stage1 <= cap_flag_stage2;
            cap_detect_stage1 <= cap_meta_stage2;
        end
    end
    
    // Shadow domain clock crossing - stage 2: secondary metastability resolution
    always @(posedge clk_shd or negedge rst_n_shd) begin
        if (!rst_n_shd) begin
            cap_meta_stage2 <= 0;
            cap_detect_stage2 <= 0;
        end else begin
            cap_meta_stage2 <= cap_meta_stage1;
            cap_detect_stage2 <= cap_detect_stage1;
        end
    end
    
    // Shadow domain data capture stage 1: capture logic
    always @(posedge clk_shd or negedge rst_n_shd) begin
        if (!rst_n_shd) begin
            cap_sync_stage1 <= 0;
        end else begin
            if (cap_detect_stage2 && !cap_sync_stage2) begin
                cap_sync_stage1 <= 1'b1;
            end else if (!cap_detect_stage2) begin
                cap_sync_stage1 <= 1'b0;
            end
        end
    end
    
    // Shadow domain data capture stage 2: data registration and handshake
    always @(posedge clk_shd or negedge rst_n_shd) begin
        if (!rst_n_shd) begin
            cap_sync_stage2 <= 0;
            shadow_data <= 0;
        end else begin
            cap_sync_stage2 <= cap_sync_stage1;
            
            if (cap_detect_stage2 && !cap_sync_stage2 && cap_sync_stage1) begin
                shadow_data <= pri_reg_stage2;
            end
        end
    end
endmodule