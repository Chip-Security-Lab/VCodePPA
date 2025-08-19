module cdc_clock_gate (
    input  wire src_clk,
    input  wire dst_clk,
    input  wire src_en,
    input  wire rst_n,
    output wire gated_dst_clk
);
    reg meta, sync;
    
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            meta <= 1'b0;
            sync <= 1'b0;
        end else begin
            meta <= src_en;
            sync <= meta;
        end
    end
    
    assign gated_dst_clk = dst_clk & sync;
endmodule