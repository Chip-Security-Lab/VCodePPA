//SystemVerilog
module clock_enable_sync (
    input wire fast_clk, 
    input wire slow_clk, 
    input wire rst_n,
    input wire enable_src,
    output reg enable_dst
);
    // Source domain register
    reg enable_src_stage1;

    // Destination domain pipeline registers (increased pipeline depth to 4 stages)
    reg enable_dst_stage1;
    reg enable_dst_stage2;
    reg enable_dst_stage3;
    reg enable_dst_stage4;

    // Capture in source (slow) clock domain
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n)
            enable_src_stage1 <= 1'b0;
        else
            enable_src_stage1 <= enable_src;
    end

    // Synchronize to destination (fast) domain with deeper pipeline
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_dst_stage1 <= 1'b0;
            enable_dst_stage2 <= 1'b0;
            enable_dst_stage3 <= 1'b0;
            enable_dst_stage4 <= 1'b0;
            enable_dst       <= 1'b0;
        end else begin
            enable_dst_stage1 <= enable_src_stage1;
            enable_dst_stage2 <= enable_dst_stage1;
            enable_dst_stage3 <= enable_dst_stage2;
            enable_dst_stage4 <= enable_dst_stage3;
            enable_dst        <= enable_dst_stage4;
        end
    end

endmodule