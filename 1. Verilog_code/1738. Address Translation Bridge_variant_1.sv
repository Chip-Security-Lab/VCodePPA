//SystemVerilog
module addr_trans_bridge #(parameter DWIDTH=32, AWIDTH=16) (
    input clk, rst_n,
    input [AWIDTH-1:0] src_addr,
    input [DWIDTH-1:0] src_data,
    input src_valid,
    output reg src_ready,
    output reg [AWIDTH-1:0] dst_addr,
    output reg [DWIDTH-1:0] dst_data,
    output reg dst_valid,
    input dst_ready
);
    // Pipeline registers - stage 1 (address checking)
    reg [AWIDTH-1:0] addr_stage1;
    reg [DWIDTH-1:0] data_stage1;
    reg valid_stage1;
    reg in_range_stage1;
    
    // Pipeline registers - stage 2 (address translation)
    reg [AWIDTH-1:0] addr_stage2;
    reg [DWIDTH-1:0] data_stage2;
    reg valid_stage2;
    
    // Pipeline registers - stage 3 (output preparation)
    reg [AWIDTH-1:0] addr_stage3;
    reg [DWIDTH-1:0] data_stage3;
    reg valid_stage3;
    
    // Configuration parameters
    reg [AWIDTH-1:0] base_addr = 'h1000;  // Example base address
    reg [AWIDTH-1:0] limit_addr = 'h2000; // Example limit
    
    // Pipeline control signals
    reg stall_pipeline;
    
    // Determine when to stall the pipeline
    always @(*) begin
        stall_pipeline = dst_valid && !dst_ready;
    end
    
    // Stage 1: Address validation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            data_stage1 <= 0;
            valid_stage1 <= 0;
            in_range_stage1 <= 0;
            src_ready <= 1;
        end else if (!stall_pipeline) begin
            addr_stage1 <= src_addr;
            data_stage1 <= src_data;
            valid_stage1 <= src_valid && src_ready;
            in_range_stage1 <= (src_addr >= base_addr && src_addr < limit_addr);
            src_ready <= 1;
        end
    end
    
    // Stage 2: Address translation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= 0;
            data_stage2 <= 0;
            valid_stage2 <= 0;
        end else if (!stall_pipeline) begin
            addr_stage2 <= addr_stage1 - (in_range_stage1 ? base_addr : 0);
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1 && in_range_stage1;
        end
    end
    
    // Stage 3: Output preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage3 <= 0;
            data_stage3 <= 0;
            valid_stage3 <= 0;
        end else if (!stall_pipeline) begin
            addr_stage3 <= addr_stage2;
            data_stage3 <= data_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dst_addr <= 0;
            dst_data <= 0;
            dst_valid <= 0;
        end else if (!stall_pipeline) begin
            dst_addr <= addr_stage3;
            dst_data <= data_stage3;
            dst_valid <= valid_stage3;
        end else if (dst_ready) begin
            dst_valid <= 0;
        end
    end
endmodule