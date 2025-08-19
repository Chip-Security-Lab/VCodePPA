//SystemVerilog
module i2c_bus_monitor(
    input wire clk, rst_n,
    input wire enable_monitor,
    output reg bus_busy,
    output reg [7:0] last_addr, last_data,
    output reg error_detected,
    inout wire sda, scl
);
    // 内部信号定义
    reg sda_prev, scl_prev;
    reg sda_meta, scl_meta; // 用于输入同步的亚稳态寄存器
    reg [2:0] monitor_state, monitor_state_r;
    reg [7:0] shift_reg;
    reg [3:0] bit_count;
    
    // 流水线寄存器
    reg start_cond_r, stop_cond_r;
    reg scl_posedge_r;
    
    // I2C条件检测 - 拆分为两级流水线
    wire sda_falling = sda_prev && !sda;
    wire sda_rising = !sda_prev && sda;
    wire scl_posedge = !scl_prev && scl;
    
    // 第一级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_cond_r <= 1'b0;
            stop_cond_r <= 1'b0;
            scl_posedge_r <= 1'b0;
        end else if (enable_monitor) begin
            start_cond_r <= scl && sda_falling;
            stop_cond_r <= scl && sda_rising;
            scl_posedge_r <= scl_posedge;
        end
    end
    
    // 输入同步，减少亚稳态风险
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_meta <= 1'b1;
            scl_meta <= 1'b1;
            sda_prev <= 1'b1;
            scl_prev <= 1'b1;
        end else if (enable_monitor) begin
            // 两级同步器
            sda_meta <= sda;
            scl_meta <= scl;
            sda_prev <= sda_meta;
            scl_prev <= scl_meta;
        end
    end
    
    // 总线状态管理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_busy <= 1'b0;
        end else if (enable_monitor) begin
            if (start_cond_r) begin
                bus_busy <= 1'b1;
            end else if (stop_cond_r) begin
                bus_busy <= 1'b0;
            end
        end
    end
    
    // 状态机控制 - 流水线化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            monitor_state <= 3'b000;
            monitor_state_r <= 3'b000;
        end else if (enable_monitor) begin
            monitor_state_r <= monitor_state;
            
            if (start_cond_r) begin
                monitor_state <= 3'b001;
            end else if (stop_cond_r) begin
                monitor_state <= 3'b000;
            end else if (bit_count == 4'b1000 && scl_posedge_r) begin
                // 根据当前状态推进到下一状态
                if (monitor_state == 3'b001) begin
                    monitor_state <= 3'b010;
                end else if (monitor_state == 3'b010) begin
                    monitor_state <= 3'b011;
                end
            end
        end
    end
    
    // 位计数器控制 - 简化条件判断
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_count <= 4'b0000;
        end else if (enable_monitor) begin
            if (start_cond_r || stop_cond_r) begin
                bit_count <= 4'b0000;
            end else if (scl_posedge_r && monitor_state != 3'b000) begin
                if (bit_count == 4'b1000) begin
                    bit_count <= 4'b0000;
                end else begin
                    bit_count <= bit_count + 1'b1;
                end
            end
        end
    end
    
    // 数据移位寄存器中间状态
    reg [6:0] shift_reg_temp;
    
    // 数据移位寄存器 - 拆分为两级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'h00;
            shift_reg_temp <= 7'h00;
        end else if (enable_monitor) begin
            if (start_cond_r) begin
                shift_reg <= 8'h00;
                shift_reg_temp <= 7'h00;
            end else if (scl_posedge_r && monitor_state != 3'b000) begin
                // 第一级：准备数据
                shift_reg_temp <= shift_reg[6:0];
                // 第二级：完成移位
                shift_reg <= {shift_reg_temp, sda_prev};
            end
        end
    end
    
    // 地址和数据捕获 - 流水线化处理
    reg should_capture_addr, should_capture_data;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            should_capture_addr <= 1'b0;
            should_capture_data <= 1'b0;
        end else if (enable_monitor) begin
            should_capture_addr <= (bit_count == 4'b0111) && scl_posedge_r && (monitor_state == 3'b001);
            should_capture_data <= (bit_count == 4'b0111) && scl_posedge_r && (monitor_state == 3'b010);
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_addr <= 8'h00;
            last_data <= 8'h00;
        end else if (enable_monitor) begin
            if (should_capture_addr) begin
                last_addr <= {shift_reg_temp, sda_prev};
            end else if (should_capture_data) begin
                last_data <= {shift_reg_temp, sda_prev};
            end
        end
    end
    
    // 错误检测 - 简化逻辑，减少关键路径
    reg premature_stop;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            premature_stop <= 1'b0;
        end else if (enable_monitor) begin
            premature_stop <= stop_cond_r && (bit_count != 4'b0000);
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_detected <= 1'b0;
        end else if (enable_monitor) begin
            if (premature_stop) begin
                error_detected <= 1'b1;
            end else if (start_cond_r) begin
                error_detected <= 1'b0;
            end
        end
    end
    
endmodule