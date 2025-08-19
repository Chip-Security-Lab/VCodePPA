//SystemVerilog
module dram_cdc_sync #(
    parameter SYNC_STAGES = 2
)(
    input src_clk,
    input dst_clk, 
    input async_cmd,
    output reg sync_cmd
);

    // 实例化同步链子模块
    sync_chain #(
        .SYNC_STAGES(SYNC_STAGES)
    ) u_sync_chain (
        .dst_clk(dst_clk),
        .async_cmd(async_cmd),
        .sync_cmd(sync_cmd)
    );

endmodule

// 同步链子模块
module sync_chain #(
    parameter SYNC_STAGES = 2
)(
    input dst_clk,
    input async_cmd,
    output reg sync_cmd
);
    
    reg [SYNC_STAGES-1:0] sync_chain;
    reg [SYNC_STAGES-1:0] sync_chain_buf;
    
    // 第一级同步寄存器
    always @(posedge dst_clk) begin
        sync_chain[0] <= async_cmd;
    end
    
    // 中间级同步寄存器
    genvar i;
    generate
        for(i=1; i<SYNC_STAGES; i=i+1) begin: gen_sync
            always @(posedge dst_clk) begin
                sync_chain[i] <= sync_chain[i-1];
            end
        end
    endgenerate
    
    // 输出缓冲寄存器
    always @(posedge dst_clk) begin
        sync_chain_buf <= sync_chain;
        sync_cmd <= sync_chain_buf[SYNC_STAGES-1];
    end

endmodule