//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module i2c_bus_monitor(
    input wire clk, rst_n,
    input wire enable_monitor,
    output reg bus_busy,
    output reg [7:0] last_addr, last_data,
    output reg error_detected,
    inout wire sda, scl
);
    // 输入信号寄存及前一个周期值
    reg sda_reg, scl_reg, sda_prev, scl_prev;
    
    // 状态和数据处理寄存器
    reg [2:0] monitor_state;
    reg [7:0] shift_reg;
    reg [3:0] bit_count;
    
    // 状态定义常量，优化可读性和计算
    localparam IDLE      = 3'b000,
               ADDR      = 3'b001,
               ADDR_ACK  = 3'b010,
               DATA      = 3'b011,
               DATA_ACK  = 3'b100;
    
    // 捕获输入信号 - 分离时序路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_reg <= 1'b1;
            scl_reg <= 1'b1;
        end else begin
            sda_reg <= sda;
            scl_reg <= scl;
        end
    end
    
    // 前一个周期值寄存 - 分离时序路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_prev <= 1'b1;
            scl_prev <= 1'b1;
        end else begin
            sda_prev <= sda_reg;
            scl_prev <= scl_reg;
        end
    end
    
    // 计算条件信号 - 提前产生组合逻辑以降低路径深度
    wire start_cond = scl_reg && sda_prev && !sda_reg;
    wire stop_cond = scl_reg && !sda_prev && sda_reg;
    wire scl_rising = scl_reg && !scl_prev;
    wire byte_complete = (bit_count == 4'h7) && scl_rising;
    wire need_state_change = (bit_count == 4'h8) && scl_rising;
    
    // 分解路径长的组合逻辑，使用单独的位计数更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_count <= 4'h0;
        end else if (enable_monitor) begin
            if (start_cond) begin
                bit_count <= 4'h0;
            end else if (bus_busy && scl_rising) begin
                if (bit_count == 4'h8) begin
                    bit_count <= 4'h0;
                end else begin
                    bit_count <= bit_count + 1'b1;
                end
            end
        end
    end
    
    // 数据移位寄存器逻辑 - 分离数据路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'h00;
        end else if (enable_monitor && bus_busy && scl_rising && bit_count < 8) begin
            shift_reg <= {shift_reg[6:0], sda_reg};
        end
    end
    
    // 总线状态控制和数据捕获 - 优化状态机结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            monitor_state <= IDLE;
            bus_busy <= 1'b0;
            last_addr <= 8'h00;
            last_data <= 8'h00;
            error_detected <= 1'b0;
        end else if (enable_monitor) begin
            if (start_cond) begin
                bus_busy <= 1'b1;
                monitor_state <= ADDR;
                error_detected <= 1'b0;
            end else if (stop_cond) begin
                bus_busy <= 1'b0;
                monitor_state <= IDLE;
            end else if (bus_busy && need_state_change) begin
                case (monitor_state)
                    ADDR: begin
                        last_addr <= shift_reg;
                        monitor_state <= ADDR_ACK;
                    end
                    ADDR_ACK: begin
                        monitor_state <= DATA;
                    end
                    DATA: begin
                        last_data <= shift_reg;
                        monitor_state <= DATA_ACK;
                    end
                    DATA_ACK: begin
                        monitor_state <= DATA;
                    end
                    default: monitor_state <= IDLE;
                endcase
            end
        end
    end
endmodule