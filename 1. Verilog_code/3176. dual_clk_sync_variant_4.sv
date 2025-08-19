//SystemVerilog
module dual_clk_sync_pipelined (
    input  wire src_clk,
    input  wire dst_clk,
    input  wire rst_n,
    input  wire pulse_in,
    output wire pulse_out
);
    // 流水线寄存器
    reg toggle_stage1;
    reg [1:0] sync_stage1, sync_stage2;
    reg signal_prev_stage1, signal_prev_stage2;
    reg pulse_stage1, pulse_stage2;
    
    // 源时钟域流水线
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_stage1 <= 1'b0;
        end else if (pulse_in) begin
            toggle_stage1 <= ~toggle_stage1;
        end
    end
    
    // 跨时钟域同步流水线
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage1 <= 2'b00;
            sync_stage2 <= 2'b00;
        end else begin
            sync_stage1 <= {sync_stage1[0], toggle_stage1};
            sync_stage2 <= sync_stage1;
        end
    end
    
    // 目标时钟域流水线
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_prev_stage1 <= 1'b0;
            signal_prev_stage2 <= 1'b0;
            pulse_stage1 <= 1'b0;
            pulse_stage2 <= 1'b0;
        end else begin
            signal_prev_stage1 <= sync_stage2[1];
            signal_prev_stage2 <= signal_prev_stage1;
            pulse_stage1 <= sync_stage2[1] ^ signal_prev_stage1;
            pulse_stage2 <= pulse_stage1;
        end
    end
    
    assign pulse_out = pulse_stage2;
endmodule