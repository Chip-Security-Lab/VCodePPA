//SystemVerilog
module edge_triggered_ismu #(parameter SRC_COUNT = 8)(
    input wire clk, rst_n,
    input wire [SRC_COUNT-1:0] intr_sources,
    input wire [SRC_COUNT-1:0] intr_mask,
    output reg [SRC_COUNT-1:0] pending_intr,
    output reg intr_valid
);
    // Clock distribution network
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // Buffered clock generation to reduce fanout
    assign clk_buf1 = clk;  // Buffer for stage 1
    assign clk_buf2 = clk;  // Buffer for stage 2
    assign clk_buf3 = clk;  // Buffer for final stage
    
    // Pipeline Stage 1: Edge detection
    reg [SRC_COUNT-1:0] intr_sources_r;
    reg [SRC_COUNT-1:0] intr_mask_stage1;
    reg [SRC_COUNT-1:0] edge_detected_stage1;
    reg valid_stage1;
    
    // Pipeline Stage 2: Interrupt accumulation
    reg [SRC_COUNT-1:0] edge_detected_stage2;
    reg valid_stage2;
    
    // Stage 1: Edge detection logic
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n) begin
            intr_sources_r <= 0;
            intr_mask_stage1 <= 0;
            edge_detected_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            intr_sources_r <= intr_sources;
            intr_mask_stage1 <= intr_mask;
            edge_detected_stage1 <= intr_sources & ~intr_sources_r & ~intr_mask;
            valid_stage1 <= 1'b1; // Valid signal for pipeline flow control
        end
    end
    
    // Stage 2: Interrupt accumulation
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n) begin
            edge_detected_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            edge_detected_stage2 <= edge_detected_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Final stage: Update pending interrupts and valid signal
    always @(posedge clk_buf3 or negedge rst_n) begin
        if (!rst_n) begin
            pending_intr <= 0;
            intr_valid <= 0;
        end else if (valid_stage2) begin
            pending_intr <= pending_intr | edge_detected_stage2;
            intr_valid <= |(pending_intr | edge_detected_stage2);
        end
    end
endmodule