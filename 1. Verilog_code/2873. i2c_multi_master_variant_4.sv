//SystemVerilog
module i2c_multi_master #(
    parameter ARB_TIMEOUT = 1000  // Arbitration timeout cycles
)(
    input clk,
    input rst,
    input [7:0] tx_data,
    output reg [7:0] rx_data,
    output reg bus_busy,
    inout sda,
    inout scl
);
    // 状态与控制信号
    reg sda_prev, scl_prev;
    reg sda_meta, sda_sync;
    reg [15:0] timeout_cnt;
    reg arbitration_lost;
    reg tx_oen;
    reg scl_oen;
    reg [2:0] bit_cnt;
    
    // 预先计算与流水线寄存器
    reg [15:0] timeout_cnt_incr;
    reg timeout_reached;
    reg arbitration_conflict;
    reg bit_data;
    reg bit_data_r;

    // 输入同步电路 - 双触发器同步器
    always @(posedge clk) begin
        if (rst) begin
            sda_meta <= 1'b1;
            sda_sync <= 1'b1;
        end else begin
            sda_meta <= sda;
            sda_sync <= sda_meta;
        end
    end
    
    // 冲突检测逻辑 - 分离判断逻辑降低路径复杂度
    always @(posedge clk) begin
        if (rst) begin
            arbitration_conflict <= 1'b0;
        end else begin
            arbitration_conflict <= (sda_sync != sda_prev) && bus_busy;
        end
    end
    
    // 计数器预计算与超时检测 - 并行化处理
    always @(posedge clk) begin
        if (rst) begin
            timeout_cnt_incr <= 16'h0000;
            timeout_reached <= 1'b0;
        end else begin
            timeout_cnt_incr <= timeout_cnt + 1'b1;
            timeout_reached <= (timeout_cnt >= (ARB_TIMEOUT - 2'd2)) && bus_busy;
        end
    end
    
    // 主状态机 - 分割关键路径，降低逻辑深度
    always @(posedge clk) begin
        if (rst) begin
            bus_busy <= 1'b0;
            arbitration_lost <= 1'b0;
            sda_prev <= 1'b1;
            scl_prev <= 1'b1;
            timeout_cnt <= 16'h0000;
            tx_oen <= 1'b1;
            scl_oen <= 1'b1;
            bit_cnt <= 3'b000;
        end else begin
            // 更新历史值 
            sda_prev <= sda_sync;
            scl_prev <= scl;
            
            // 仲裁丢失检测 - 使用预计算结果
            if (arbitration_conflict) begin
                arbitration_lost <= 1'b1;
            end
            
            // 超时逻辑 - 使用预计算的超时标志
            if (bus_busy) begin
                timeout_cnt <= timeout_cnt_incr;
                
                if (timeout_reached) begin
                    bus_busy <= 1'b0;
                    tx_oen <= 1'b1;
                    scl_oen <= 1'b1;
                end
            end
        end
    end

    // 位数据计算 - 双级流水线以减少关键路径
    always @(posedge clk) begin
        if (rst) begin
            bit_data <= 1'b1;
            bit_data_r <= 1'b1;
        end else begin
            bit_data <= tx_data[bit_cnt];
            bit_data_r <= bit_data;
        end
    end

    // 三态控制与总线监控 - 使用流水线寄存器减少组合路径
    assign sda = (tx_oen) ? bit_data_r : 1'bz;
    assign scl = (scl_oen) ? 1'b0 : 1'bz;
endmodule