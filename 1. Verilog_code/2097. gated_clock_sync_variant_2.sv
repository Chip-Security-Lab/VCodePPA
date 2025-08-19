//SystemVerilog
module gated_clock_sync (
    input src_clk,
    input dst_gclk,
    input rst,
    input data_in,
    output reg data_out
);
    reg sync_stage_d;
    reg sync_stage_q;

    // Move the register after the combinational logic
    always @(*) begin
        sync_stage_d = rst ? 1'b0 : data_in;
    end

    always @(posedge src_clk) begin
        sync_stage_q <= sync_stage_d;
    end

    always @(posedge dst_gclk) begin
        data_out <= sync_stage_q;
    end
endmodule