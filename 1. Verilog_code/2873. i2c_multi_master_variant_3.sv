//SystemVerilog
//IEEE 1364-2005 Verilog
module i2c_multi_master #(
    parameter ARB_TIMEOUT = 1000  // Arbitration timeout cycles
)(
    input wire clk,
    input wire rst,
    input wire [7:0] tx_data,
    input wire tx_valid,          // 输入数据有效信号
    output reg tx_ready,          // 可以接收新数据的信号
    output reg [7:0] rx_data,
    output reg rx_valid,          // 接收数据有效信号
    input wire rx_ready,          // 下游模块可以接收数据的信号
    output reg bus_busy,
    inout wire sda,
    inout wire scl
);

    // 流水线阶段定义
    localparam STAGE_IDLE  = 2'd0;
    localparam STAGE_START = 2'd1;
    localparam STAGE_DATA  = 2'd2;
    localparam STAGE_STOP  = 2'd3;

    // 流水线寄存器和控制信号
    reg [1:0] stage_current, stage_next;
    reg [7:0] tx_data_stage1, tx_data_stage2;
    reg tx_valid_stage1, tx_valid_stage2;
    reg [2:0] bit_cnt, bit_cnt_next;
    reg bus_busy_stage1;
    reg arbitration_lost, arbitration_lost_next;
    
    // I2C信号和监控寄存器
    reg sda_prev, scl_prev;
    reg sda_out, scl_out;
    reg sda_oen, scl_oen;
    
    // 使用跳跃进位加法器实现超时计数
    reg [15:0] timeout_cnt;
    wire [15:0] timeout_cnt_next;
    
    // SDA和SCL三态控制
    assign sda = sda_oen ? 1'bz : sda_out;
    assign scl = scl_oen ? 1'bz : scl_out;

    // 检测总线起始条件
    wire start_condition_detected = (sda_prev == 1'b1) && (sda == 1'b0) && (scl == 1'b1);

    // 实现跳跃进位加法器
    wire timeout_inc = bus_busy_stage1;
    wire timeout_clr = !bus_busy_stage1 || (timeout_cnt >= ARB_TIMEOUT);
    
    // 生成和传播信号
    wire [15:0] g; // 生成信号
    wire [15:0] p; // 传播信号
    wire [16:0] c; // 进位信号 (额外一位用于最终进位)
    
    // 初始生成和传播条件
    assign g[0] = timeout_inc & timeout_cnt[0];
    assign p[0] = timeout_inc ^ timeout_cnt[0];
    
    // 第一级：计算每一位的生成和传播信号
    genvar i;
    generate
        for (i = 1; i < 16; i = i + 1) begin: gen_gp
            assign g[i] = timeout_inc & timeout_cnt[i];
            assign p[i] = timeout_inc ^ timeout_cnt[i];
        end
    endgenerate
    
    // 第二级：跳跃进位计算
    assign c[0] = timeout_inc;
    
    // 4位分组的跳跃进位
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g[3] | (p[3] & c[3]);
    
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & c[5]);
    assign c[7] = g[6] | (p[6] & c[6]);
    assign c[8] = g[7] | (p[7] & c[7]);
    
    assign c[9] = g[8] | (p[8] & c[8]);
    assign c[10] = g[9] | (p[9] & c[9]);
    assign c[11] = g[10] | (p[10] & c[10]);
    assign c[12] = g[11] | (p[11] & c[11]);
    
    assign c[13] = g[12] | (p[12] & c[12]);
    assign c[14] = g[13] | (p[13] & c[13]);
    assign c[15] = g[14] | (p[14] & c[14]);
    assign c[16] = g[15] | (p[15] & c[15]);
    
    // 计算结果
    assign timeout_cnt_next = timeout_clr ? 16'h0000 : 
                             {p[15] ^ c[15], 
                              p[14] ^ c[14],
                              p[13] ^ c[13],
                              p[12] ^ c[12],
                              p[11] ^ c[11],
                              p[10] ^ c[10],
                              p[9] ^ c[9],
                              p[8] ^ c[8],
                              p[7] ^ c[7],
                              p[6] ^ c[6],
                              p[5] ^ c[5],
                              p[4] ^ c[4],
                              p[3] ^ c[3],
                              p[2] ^ c[2],
                              p[1] ^ c[1],
                              p[0] ^ c[0]};

    // 流水线第一级：状态控制和输入处理
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pipeline_stage1_reset();
        end else begin
            pipeline_stage1_update();
        end
    end

    // 流水线第二级：执行I2C总线操作和仲裁检测
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pipeline_stage2_reset();
        end else begin
            pipeline_stage2_update();
        end
    end

    // 组合逻辑：流水线控制
    always @* begin
        pipeline_control_logic();
    end

    // ===== 可复用任务定义 =====
    
    // 流水线第一级复位任务
    task pipeline_stage1_reset;
        begin
            stage_current <= STAGE_IDLE;
            tx_data_stage1 <= 8'h00;
            tx_valid_stage1 <= 1'b0;
            bus_busy_stage1 <= 1'b0;
            timeout_cnt <= 16'h0000;
            sda_prev <= 1'b1;
            scl_prev <= 1'b1;
            tx_ready <= 1'b1;
        end
    endtask

    // 流水线第一级更新任务
    task pipeline_stage1_update;
        begin
            stage_current <= stage_next;
            tx_data_stage1 <= tx_valid && tx_ready ? tx_data : tx_data_stage1;
            tx_valid_stage1 <= tx_valid && tx_ready ? 1'b1 : 
                              (stage_current == STAGE_STOP) ? 1'b0 : tx_valid_stage1;
            bus_busy_stage1 <= bus_busy;
            timeout_cnt <= timeout_cnt_next;
            sda_prev <= sda;
            scl_prev <= scl;
            tx_ready <= (stage_current == STAGE_IDLE) || (stage_current == STAGE_STOP);
        end
    endtask

    // 流水线第二级复位任务
    task pipeline_stage2_reset;
        begin
            tx_data_stage2 <= 8'h00;
            tx_valid_stage2 <= 1'b0;
            bit_cnt <= 3'b000;
            arbitration_lost <= 1'b0;
            bus_busy <= 1'b0;
            sda_out <= 1'b1;
            scl_out <= 1'b1;
            sda_oen <= 1'b1;
            scl_oen <= 1'b1;
            rx_data <= 8'h00;
            rx_valid <= 1'b0;
        end
    endtask

    // 流水线第二级更新任务
    task pipeline_stage2_update;
        begin
            tx_data_stage2 <= tx_data_stage1;
            tx_valid_stage2 <= tx_valid_stage1;
            bit_cnt <= bit_cnt_next;
            arbitration_lost <= arbitration_lost_next;
            bus_busy <= (stage_current != STAGE_IDLE) || start_condition_detected;
            
            // 根据流水线阶段设置SDA和SCL控制
            case (stage_current)
                STAGE_IDLE: begin
                    configure_idle_state();
                end
                
                STAGE_START: begin
                    configure_start_state();
                end
                
                STAGE_DATA: begin
                    configure_data_state();
                end
                
                STAGE_STOP: begin
                    configure_stop_state();
                end
            endcase
        end
    endtask

    // 配置空闲状态
    task configure_idle_state;
        begin
            sda_out <= 1'b1;
            scl_out <= 1'b1;
            sda_oen <= 1'b1;
            scl_oen <= 1'b1;
            rx_valid <= 1'b0;
        end
    endtask

    // 配置起始状态
    task configure_start_state;
        begin
            sda_out <= 1'b0;
            scl_out <= bit_cnt[0] ? 1'b0 : 1'b1;
            sda_oen <= 1'b0;
            scl_oen <= bit_cnt[0] ? 1'b0 : 1'b1;
        end
    endtask

    // 配置数据传输状态
    task configure_data_state;
        begin
            sda_out <= tx_data_stage2[7-bit_cnt];
            scl_out <= 1'b0;
            sda_oen <= 1'b0;
            scl_oen <= bit_cnt[0] ? 1'b0 : 1'b1;
            
            // 当SCL上升沿时，读取SDA数据
            if (scl_prev == 1'b0 && scl == 1'b1) begin
                rx_data[7-bit_cnt] <= sda;
            end
            
            // 最后一位数据完成时，设置接收有效
            if (bit_cnt == 3'b111 && scl_prev == 1'b1 && scl == 1'b0) begin
                rx_valid <= 1'b1;
            end
        end
    endtask

    // 配置停止状态
    task configure_stop_state;
        begin
            sda_out <= bit_cnt[0] ? 1'b1 : 1'b0;
            scl_out <= 1'b1;
            sda_oen <= 1'b0;
            scl_oen <= 1'b1;
            rx_valid <= 1'b0;
        end
    endtask

    // 流水线控制逻辑
    task pipeline_control_logic;
        begin
            // 默认值
            stage_next = stage_current;
            bit_cnt_next = bit_cnt;
            arbitration_lost_next = arbitration_lost;
            
            // 仲裁丢失检测
            check_arbitration_loss();
            
            // 流水线状态转换逻辑
            case (stage_current)
                STAGE_IDLE: begin
                    handle_idle_state();
                end
                
                STAGE_START: begin
                    handle_start_state();
                end
                
                STAGE_DATA: begin
                    handle_data_state();
                end
                
                STAGE_STOP: begin
                    handle_stop_state();
                end
            endcase
        end
    endtask

    // 仲裁丢失检测子任务
    task check_arbitration_loss;
        begin
            if (sda != sda_prev && bus_busy_stage1 && stage_current != STAGE_IDLE) begin
                arbitration_lost_next = 1'b1;
            end
        end
    endtask

    // IDLE状态处理子任务
    task handle_idle_state;
        begin
            bit_cnt_next = 3'b000;
            if (tx_valid_stage1 && !bus_busy_stage1) begin
                stage_next = STAGE_START;
            end
        end
    endtask

    // START状态处理子任务
    task handle_start_state;
        begin
            if (bit_cnt == 3'b001) begin
                bit_cnt_next = 3'b000;
                stage_next = STAGE_DATA;
            end else begin
                bit_cnt_next = bit_cnt + 1;
            end
        end
    endtask

    // DATA状态处理子任务
    task handle_data_state;
        begin
            if (bit_cnt == 3'b111 && scl_prev == 1'b1 && scl == 1'b0) begin
                if (rx_ready) begin
                    bit_cnt_next = 3'b000;
                    stage_next = STAGE_STOP;
                end
            end else if (scl_prev == 1'b1 && scl == 1'b0) begin
                bit_cnt_next = bit_cnt + 1;
            end
            
            if (arbitration_lost) begin
                stage_next = STAGE_IDLE;
            end
        end
    endtask

    // STOP状态处理子任务
    task handle_stop_state;
        begin
            if (bit_cnt == 3'b001) begin
                bit_cnt_next = 3'b000;
                stage_next = STAGE_IDLE;
                arbitration_lost_next = 1'b0;
            end else begin
                bit_cnt_next = bit_cnt + 1;
            end
        end
    endtask

endmodule