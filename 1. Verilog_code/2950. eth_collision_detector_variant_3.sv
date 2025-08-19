//SystemVerilog
// SystemVerilog
module eth_collision_detector (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       transmitting,
    input  wire       receiving,
    input  wire       carrier_sense,
    output reg        collision_detected,
    output reg        jam_active,
    output reg  [3:0] backoff_count,
    output reg [15:0] backoff_time
);

    // 常量定义
    localparam JAM_SIZE    = 8'd32;   // 32-byte jam pattern (16-bit time)
    localparam MAX_BACKOFF = 16'd1023; // 2^10 - 1
    
    // ===== 第一级：碰撞检测阶段 =====
    // 碰撞条件检测逻辑
    wire collision_condition;
    wire reset_condition;
    reg  collision_detected_stage1;
    reg  transmitting_r, receiving_r, carrier_sense_r;
    
    // 寄存输入信号，改善时序
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            transmitting_r  <= 1'b0;
            receiving_r     <= 1'b0;
            carrier_sense_r <= 1'b0;
        end else begin
            transmitting_r  <= transmitting;
            receiving_r     <= receiving;
            carrier_sense_r <= carrier_sense;
        end
    end
    
    // 优化为清晰的组合逻辑
    assign collision_condition = transmitting_r & (receiving_r | carrier_sense_r);
    assign reset_condition = ~transmitting_r & ~receiving_r & ~collision_detected & (collision_count > 4'd0);
    
    // ===== 第二级：碰撞计数和退避时间计算 =====
    reg [3:0]  collision_count;
    reg [3:0]  next_collision_count;
    reg [3:0]  next_backoff_count;
    reg [15:0] next_backoff_time;
    
    // 碰撞计数更新逻辑
    always @(*) begin
        // 默认保持当前值
        next_collision_count = collision_count;
        next_backoff_count = backoff_count;
        next_backoff_time = backoff_time;
        
        if (collision_condition && !collision_detected) begin
            // 碰撞发生且之前未检测到
            next_collision_count = collision_count + 1'b1;
            next_backoff_count = collision_count + 1'b1;
            
            // 优化的退避时间计算
            if (collision_count < 4'd10) begin
                next_backoff_time = (16'd1 << collision_count) - 16'd1;
            end else begin
                next_backoff_time = MAX_BACKOFF;
            end
        end else if (reset_condition) begin
            // 重置碰撞计数
            next_collision_count = 4'd0;
        end
    end
    
    // 更新计数器寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            collision_count <= 4'd0;
            backoff_count <= 4'd0;
            backoff_time <= 16'd0;
        end else begin
            collision_count <= next_collision_count;
            backoff_count <= next_backoff_count;
            backoff_time <= next_backoff_time;
        end
    end
    
    // ===== 第三级：JAM信号生成阶段 =====
    reg [7:0] jam_counter;
    reg [7:0] next_jam_counter;
    reg       next_jam_active;
    reg       next_collision_detected;
    
    // JAM信号状态更新逻辑
    always @(*) begin
        // 默认保持当前值
        next_jam_counter = jam_counter;
        next_jam_active = jam_active;
        next_collision_detected = collision_detected;
        
        if (collision_condition) begin
            // 碰撞发生时启动JAM信号
            next_collision_detected = 1'b1;
            next_jam_active = 1'b1;
            next_jam_counter = JAM_SIZE;
        end else if (!transmitting_r) begin
            // 传输结束时清除碰撞标志
            next_collision_detected = 1'b0;
        end
        
        // JAM信号计数逻辑
        if (jam_active && (jam_counter > 8'd0)) begin
            next_jam_counter = jam_counter - 8'd1;
        end else if (jam_active) begin
            next_jam_active = 1'b0;
        end
    end
    
    // 更新JAM信号控制寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            collision_detected <= 1'b0;
            jam_active <= 1'b0;
            jam_counter <= 8'd0;
        end else begin
            collision_detected <= next_collision_detected;
            jam_active <= next_jam_active;
            jam_counter <= next_jam_counter;
        end
    end

endmodule