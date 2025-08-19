//SystemVerilog
module i2c_bus_monitor(
    input wire clk, rst_n,
    input wire enable_monitor,
    output reg bus_busy,
    output reg [7:0] last_addr, last_data,
    output reg error_detected,
    inout wire sda, scl
);
    // 输入同步和边沿检测阶段 (Stage 1)
    reg sda_sync1, sda_sync2, sda_stage1;
    reg scl_sync1, scl_sync2, scl_stage1;
    reg sda_prev_stage1, scl_prev_stage1;
    reg enable_monitor_stage1;
    reg valid_stage1;
    
    // 条件检测和状态更新阶段 (Stage 2)
    reg start_cond_stage2, stop_cond_stage2;
    reg sda_stage2, scl_stage2;
    reg sda_prev_stage2, scl_prev_stage2;
    reg enable_monitor_stage2;
    reg [2:0] monitor_state_stage2;
    reg valid_stage2;
    
    // 数据处理阶段 (Stage 3)
    reg [7:0] shift_reg_stage3;
    reg [3:0] bit_count_stage3;
    reg [2:0] monitor_state_stage3;
    reg bus_busy_stage3;
    reg valid_stage3;
    
    // Stage 1: 输入同步和边沿检测 - 优化的同步逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {sda_sync1, sda_sync2, sda_stage1, sda_prev_stage1} <= {4{1'b1}};
            {scl_sync1, scl_sync2, scl_stage1, scl_prev_stage1} <= {4{1'b1}};
            enable_monitor_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            // 优化的多位赋值
            {sda_sync1, sda_sync2, sda_stage1, sda_prev_stage1} <= {sda, sda_sync1, sda_sync2, sda_stage1};
            {scl_sync1, scl_sync2, scl_stage1, scl_prev_stage1} <= {scl, scl_sync1, scl_sync2, scl_stage1};
            enable_monitor_stage1 <= enable_monitor;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: 条件检测和状态更新 - 优化的比较逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {start_cond_stage2, stop_cond_stage2} <= 2'b00;
            {sda_stage2, scl_stage2} <= 2'b11;
            {sda_prev_stage2, scl_prev_stage2} <= 2'b11;
            enable_monitor_stage2 <= 1'b0;
            monitor_state_stage2 <= 3'b000;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            // 优化的数据传递
            {sda_stage2, scl_stage2} <= {sda_stage1, scl_stage1};
            {sda_prev_stage2, scl_prev_stage2} <= {sda_prev_stage1, scl_prev_stage1};
            enable_monitor_stage2 <= enable_monitor_stage1;
            
            // 优化的开始/停止条件检测逻辑
            // START: SCL=1, SDA从1变为0
            // STOP: SCL=1, SDA从0变为1
            start_cond_stage2 <= scl_stage1 & sda_prev_stage1 & ~sda_stage1;
            stop_cond_stage2 <= scl_stage1 & ~sda_prev_stage1 & sda_stage1;
            
            // 优化状态机更新逻辑
            if (enable_monitor_stage1) begin
                // 使用简化的优先级编码
                case (1'b1)
                    (scl_stage1 & sda_prev_stage1 & ~sda_stage1): monitor_state_stage2 <= 3'b001; // START
                    (scl_stage1 & ~sda_prev_stage1 & sda_stage1): monitor_state_stage2 <= 3'b000; // STOP
                    default: monitor_state_stage2 <= monitor_state_stage3;
                endcase
            end
            
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: 数据处理 - 优化的数据处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage3 <= 8'h00;
            bit_count_stage3 <= 4'h0;
            monitor_state_stage3 <= 3'b000;
            bus_busy_stage3 <= 1'b0;
            last_addr <= 8'h00;
            last_data <= 8'h00;
            error_detected <= 1'b0;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            monitor_state_stage3 <= monitor_state_stage2;
            
            // 优化的条件处理逻辑
            if (start_cond_stage2) begin
                {bus_busy_stage3, bit_count_stage3, shift_reg_stage3, error_detected} <= {1'b1, 4'h0, 8'h00, 1'b0};
            end else if (stop_cond_stage2) begin
                bus_busy_stage3 <= 1'b0;
                // 检测错误条件 - 位计数不为0时的STOP是错误
                if (bit_count_stage3 != 0) begin
                    error_detected <= 1'b1;
                end
            end
            
            // 优化的位采集逻辑
            if (bus_busy_stage3 && ~scl_prev_stage2 && scl_stage2) begin // SCL上升沿
                shift_reg_stage3 <= {shift_reg_stage3[6:0], sda_stage2};
                bit_count_stage3 <= bit_count_stage3 + 1'b1;
                
                // 当收集满8位时的处理逻辑
                if (bit_count_stage3 == 4'h7) begin
                    bit_count_stage3 <= 4'h0; // 重置位计数
                    
                    // 优化的状态机处理
                    case (monitor_state_stage3)
                        3'b001: begin // 地址模式
                            last_addr <= {shift_reg_stage3[6:0], sda_stage2};
                            monitor_state_stage3 <= 3'b010; // 切换到数据模式
                        end
                        3'b010: begin // 数据模式
                            last_data <= {shift_reg_stage3[6:0], sda_stage2};
                            monitor_state_stage3 <= 3'b001; // 切换回地址模式
                        end
                        default: ; // 其他状态不变
                    endcase
                end
            end
            
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出赋值 - 流水线输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_busy <= 1'b0;
        end else if (valid_stage3) begin
            bus_busy <= bus_busy_stage3;
        end
    end
    
    // 三态输出缓冲区（保持未修改，仅监控，不驱动总线）
    
endmodule