//SystemVerilog
module gated_clock_sync (
    input  wire        src_clk,
    input  wire        dst_gclk,
    input  wire        rst,
    input  wire        data_in,
    output reg         data_out
);

// Combine input pipeline registers into one stage after input logic
wire src_comb_logic;
assign src_comb_logic = data_in;

// Move first pipeline register after combination logic
reg src_pipeline_reg /* synthesis syn_preserve=1 */;
always @(posedge src_clk) begin
    if (rst)
        src_pipeline_reg <= 1'b0;
    else
        src_pipeline_reg <= src_comb_logic;
end

// Second pipeline register for metastability reduction
reg src_metastability_reg /* synthesis syn_preserve=1 */;
always @(posedge src_clk) begin
    if (rst)
        src_metastability_reg <= 1'b0;
    else
        src_metastability_reg <= src_pipeline_reg;
end

// Synchronization to destination gated clock domain (first stage)
reg dst_sync_reg1 /* synthesis syn_preserve=1 */;
always @(posedge dst_gclk) begin
    if (rst)
        dst_sync_reg1 <= 1'b0;
    else
        dst_sync_reg1 <= src_metastability_reg;
end

// Synchronization to destination gated clock domain (second stage)
reg dst_sync_reg2 /* synthesis syn_preserve=1 */;
always @(posedge dst_gclk) begin
    if (rst)
        dst_sync_reg2 <= 1'b0;
    else
        dst_sync_reg2 <= dst_sync_reg1;
end

// Output assignment from final pipeline stage
always @(posedge dst_gclk) begin
    if (rst)
        data_out <= 1'b0;
    else
        data_out <= dst_sync_reg2;
end

endmodule