//SystemVerilog
// 顶层模块
module dram_ctrl_async #(
    parameter BANK_ADDR_WIDTH = 3,
    parameter ROW_ADDR_WIDTH = 13,
    parameter COL_ADDR_WIDTH = 10
)(
    input clk,
    input async_req,
    output reg ack,
    inout [15:0] dram_dq
);

    // 内部信号
    wire ras_n, cas_n, we_n;
    wire [BANK_ADDR_WIDTH-1:0] bank_addr;
    wire async_req_sync;
    
    // 实例化子模块
    sync_control sync_inst (
        .clk(clk),
        .async_req(async_req),
        .async_req_sync(async_req_sync)
    );
    
    cmd_generator cmd_gen_inst (
        .async_req_sync(async_req_sync),
        .ack(ack),
        .ras_n(ras_n),
        .cas_n(cas_n),
        .we_n(we_n)
    );
    
    ack_control ack_ctrl_inst (
        .clk(clk),
        .async_req_sync(async_req_sync),
        .ack(ack)
    );

endmodule

// 同步控制子模块
module sync_control #(
    parameter SYNC_STAGES = 2
)(
    input clk,
    input async_req,
    output reg async_req_sync
);

    reg [SYNC_STAGES-1:0] sync_ff;
    
    always @(posedge clk) begin
        sync_ff <= {sync_ff[SYNC_STAGES-2:0], async_req};
        async_req_sync <= sync_ff[SYNC_STAGES-1];
    end

endmodule

// 命令生成子模块
module cmd_generator #(
    parameter BANK_ADDR_WIDTH = 3
)(
    input async_req_sync,
    input ack,
    output reg ras_n,
    output reg cas_n,
    output reg we_n
);

    always @(*) begin
        if(async_req_sync && !ack) begin
            ras_n = 0;
            cas_n = 1;
            we_n = 1;
        end
        else begin
            ras_n = 1;
            cas_n = 1;
            we_n = 1;
        end
    end

endmodule

// 应答控制子模块
module ack_control(
    input clk,
    input async_req_sync,
    output reg ack
);

    always @(posedge clk) begin
        ack <= async_req_sync;
    end

endmodule