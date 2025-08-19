//SystemVerilog
module gated_clock_sync_pipeline (
    input  wire        src_clk,
    input  wire        dst_gclk,
    input  wire        rst,
    input  wire        data_in,
    output reg         data_out,
    output wire        valid_out
);

// Combined Stage: Synchronize and output register in destination gated clock domain
reg  data_stage1;
reg  valid_stage1;

always @(posedge dst_gclk or posedge rst) begin
    if (rst) begin
        data_stage1  <= 1'b0;
        valid_stage1 <= 1'b0;
        data_out     <= 1'b0;
    end else begin
        data_stage1  <= data_in;
        valid_stage1 <= 1'b1;
        data_out     <= data_stage1;
    end
end

assign valid_out = valid_stage1;

endmodule