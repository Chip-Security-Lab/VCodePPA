module MixedIVMU (
    input clk, rst_n,
    input [3:0] sync_irq,
    input [3:0] async_irq,
    input ack,
    output reg [31:0] vector,
    output wire irq_pending
);
    reg [31:0] vectors [0:7];
    reg [3:0] sync_pending, async_latched;
    reg [3:0] async_prev;
    wire [3:0] async_edge;
    integer i;
    
    // 初始化向量表
    initial begin
        vectors[0] = 32'hD000_0000;
        vectors[1] = 32'hD000_0080;
        vectors[2] = 32'hD000_0100;
        vectors[3] = 32'hD000_0180;
        vectors[4] = 32'hD000_0200;
        vectors[5] = 32'hD000_0280;
        vectors[6] = 32'hD000_0300;
        vectors[7] = 32'hD000_0380;
    end
    
    // 边沿检测逻辑修改为时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            async_prev <= 4'h0;
        end else begin
            async_prev <= async_irq;
        end
    end
    
    // 计算边沿
    assign async_edge = async_irq & ~async_prev;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_pending <= 4'h0;
            async_latched <= 4'h0;
            vector <= 32'h0;
        end else begin
            async_latched <= async_latched | async_edge;
            sync_pending <= sync_pending | sync_irq;
            
            if (ack) begin
                sync_pending <= 4'h0;
                async_latched <= 4'h0;
            end else begin
                // 优先处理异步中断
                if (async_latched[3]) begin
                    vector <= vectors[7];
                end else if (async_latched[2]) begin
                    vector <= vectors[6];
                end else if (async_latched[1]) begin
                    vector <= vectors[5];
                end else if (async_latched[0]) begin
                    vector <= vectors[4];
                // 其次处理同步中断
                end else if (sync_pending[3]) begin
                    vector <= vectors[3];
                end else if (sync_pending[2]) begin
                    vector <= vectors[2];
                end else if (sync_pending[1]) begin
                    vector <= vectors[1];
                end else if (sync_pending[0]) begin
                    vector <= vectors[0];
                end
            end
        end
    end
    
    assign irq_pending = |sync_pending | |async_latched;
endmodule