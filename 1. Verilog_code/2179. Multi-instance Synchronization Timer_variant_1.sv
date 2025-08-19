//SystemVerilog
module sync_multi_timer (
    input wire master_clk, slave_clk, reset, sync_en,
    output reg [31:0] master_count, slave_count,
    output wire synced
);
    // 将同步请求信号分解为前级组合逻辑和后级寄存器
    wire sync_req_comb;
    reg sync_req;
    reg sync_ack;
    
    // 同步移位寄存器 - 不再缓存sync_shift本身
    wire sync_req_sync_stage0;
    reg [1:0] sync_shift_stages;
    wire sync_edge_detected;
    
    // 组合逻辑提前计算
    assign sync_req_comb = sync_en & (master_count[7:0] == 8'h0);
    
    // 检测边沿的组合逻辑
    assign sync_req_sync_stage0 = sync_req;
    assign sync_edge_detected = ~sync_shift_stages[1] & sync_shift_stages[0];
    
    // Master时钟域
    always @(posedge master_clk) begin
        if (reset) begin 
            master_count <= 32'h0; 
            sync_req <= 1'b0; 
        end
        else begin
            master_count <= master_count + 32'h1;
            sync_req <= sync_req_comb;
        end
    end
    
    // Slave时钟域 - 重新组织同步逻辑，减少级联延迟
    always @(posedge slave_clk) begin
        if (reset) 
            sync_shift_stages <= 2'b0;
        else 
            sync_shift_stages <= {sync_shift_stages[0], sync_req_sync_stage0};
    end
    
    // 重组slave计数器逻辑，直接使用边沿检测结果
    always @(posedge slave_clk) begin
        if (reset) begin 
            slave_count <= 32'h0; 
            sync_ack <= 1'b0; 
        end
        else begin
            slave_count <= sync_edge_detected ? 32'h0 : slave_count + 32'h1;
            sync_ack <= sync_edge_detected;
        end
    end
    
    assign synced = sync_ack;
endmodule