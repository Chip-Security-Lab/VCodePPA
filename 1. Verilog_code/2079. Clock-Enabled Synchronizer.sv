module clock_enable_sync (
    input wire fast_clk, slow_clk, rst_n,
    input wire enable_src,
    output reg enable_dst
);
    reg enable_src_ff;
    reg enable_meta, enable_sync;
    
    // Capture on source domain
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) enable_src_ff <= 1'b0;
        else enable_src_ff <= enable_src;
    end
    
    // Synchronize to destination domain
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_meta <= 1'b0;
            enable_sync <= 1'b0;
            enable_dst <= 1'b0;
        end else begin
            enable_meta <= enable_src_ff;
            enable_sync <= enable_meta;
            enable_dst <= enable_sync;
        end
    end
endmodule
