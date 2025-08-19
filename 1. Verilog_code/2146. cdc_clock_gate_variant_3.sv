//SystemVerilog
module cdc_clock_gate (
    input  wire src_clk,
    input  wire dst_clk,
    input  wire src_en,
    input  wire rst_n,
    output wire gated_dst_clk
);
    reg meta, sync;
    
    always @(posedge dst_clk or negedge rst_n) begin
        meta <= !rst_n ? 1'b0 : src_en;
        sync <= !rst_n ? 1'b0 : meta;
    end
    
    assign gated_dst_clk = dst_clk & sync;
endmodule