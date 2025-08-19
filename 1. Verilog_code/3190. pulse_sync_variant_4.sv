//SystemVerilog
module pulse_sync #(
    parameter DST_CLK_RATIO = 2
)(
    input src_clk,
    input dst_clk,
    input src_pulse,
    output dst_pulse
);
    reg src_flag;
    reg [1:0] sync_chain;
    reg sync_chain_stage2;
    reg dst_flag_reg;
    
    always @(posedge src_clk) begin
        src_flag <= src_pulse ? ~src_flag : src_flag;
    end
    
    always @(posedge dst_clk) begin
        {sync_chain, sync_chain_stage2, dst_flag_reg} <= {sync_chain[0], src_flag, sync_chain[1], sync_chain_stage2};
    end
    
    assign dst_pulse = sync_chain_stage2 ^ dst_flag_reg;
endmodule