//SystemVerilog
module ICMU_AccessStats #(
    parameter DW = 64,
    parameter STAT_W = 8
)(
    input clk,
    input rst_n,
    input access_en,
    input [DW-1:0] ctx_addr,
    output reg [DW-1:0] hot_ctx
);
    // Stage 1: Access Count Update
    reg [STAT_W-1:0] access_count [0:(1<<DW)-1];
    reg [DW-1:0] ctx_addr_stage1;
    reg access_en_stage1;
    
    // Stage 2: Max Count Comparison
    reg [STAT_W-1:0] access_count_stage2;
    reg [DW-1:0] ctx_addr_stage2;
    reg access_en_stage2;
    reg [STAT_W-1:0] max_count_stage2;
    reg [DW-1:0] max_addr_stage2;
    
    // Stage 3: Hot Context Update
    reg [DW-1:0] max_addr_stage3;
    
    // Stage 1: Input Registering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctx_addr_stage1 <= 0;
            access_en_stage1 <= 0;
        end else begin
            ctx_addr_stage1 <= ctx_addr;
            access_en_stage1 <= access_en;
        end
    end
    
    // Stage 1: Access Count Update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all access counts
            for (int i = 0; i < (1<<DW); i++) begin
                access_count[i] <= 0;
            end
        end else if (access_en) begin
            access_count[ctx_addr] <= access_count[ctx_addr] + 1;
        end
    end
    
    // Stage 2: Access Count Registering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            access_count_stage2 <= 0;
            ctx_addr_stage2 <= 0;
            access_en_stage2 <= 0;
        end else begin
            access_count_stage2 <= access_count[ctx_addr_stage1];
            ctx_addr_stage2 <= ctx_addr_stage1;
            access_en_stage2 <= access_en_stage1;
        end
    end
    
    // Stage 2: Max Count Comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max_count_stage2 <= 0;
            max_addr_stage2 <= 0;
        end else if (access_en_stage1) begin
            if (access_count[ctx_addr_stage1] >= max_count_stage2) begin
                max_count_stage2 <= access_count[ctx_addr_stage1];
                max_addr_stage2 <= ctx_addr_stage1;
            end
        end
    end
    
    // Stage 3: Max Address Registering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max_addr_stage3 <= 0;
        end else begin
            max_addr_stage3 <= max_addr_stage2;
        end
    end
    
    // Stage 3: Hot Context Output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hot_ctx <= 0;
        end else begin
            hot_ctx <= max_addr_stage3;
        end
    end
endmodule