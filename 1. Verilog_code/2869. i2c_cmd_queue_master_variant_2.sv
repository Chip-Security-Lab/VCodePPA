//SystemVerilog - IEEE 1364-2005
module i2c_cmd_queue_master #(
    parameter QUEUE_DEPTH = 4
)(
    input clk, reset_n,
    input [7:0] cmd_data,
    input cmd_push, cmd_pop,
    output wire queue_full, queue_empty,
    output reg [7:0] rx_data,
    output reg transfer_done,
    inout scl, sda
);
    // 状态定义 - 使用one-hot编码提高效率
    localparam IDLE  = 4'b0001;
    localparam START = 4'b0010;
    localparam ADDR  = 4'b0100;
    localparam ACK1  = 4'b1000;
    localparam TX_DATA = 4'b0011;
    localparam ACK2    = 4'b0101;
    localparam STOP    = 4'b0110;
    
    // 命令队列存储
    reg [7:0] cmd_queue [0:QUEUE_DEPTH-1];
    reg [$clog2(QUEUE_DEPTH):0] head, tail;
    
    // 流水线寄存器 - 阶段划分
    // 阶段1: 命令获取和解码
    reg [3:0] state_stage1;
    reg [7:0] current_cmd_stage1;
    reg [2:0] bit_cnt_stage1; // 优化位宽为3位，只需计数0-7
    reg valid_stage1;
    
    // 阶段2: I2C信号生成
    reg [3:0] state_stage2;
    reg [7:0] current_cmd_stage2;
    reg [2:0] bit_cnt_stage2; // 优化位宽
    reg valid_stage2;
    reg sda_out_stage2, scl_out_stage2, sda_en_stage2;
    
    // 阶段3: I2C总线驱动
    reg [3:0] state_stage3;
    reg sda_out, scl_out, sda_en;
    reg valid_stage3;
    reg transfer_complete_stage3;
    
    // I2C总线驱动 - 简化的三态控制
    assign scl = scl_out ? 1'bz : 1'b0;
    assign sda = sda_en ? 1'bz : sda_out;
    
    // 队列状态逻辑 - 直接计算而非赋值
    assign queue_full = ((head + 1'b1) & (QUEUE_DEPTH-1)) == tail;
    assign queue_empty = head == tail;
    
    // 队列管理 - 入队和出队逻辑
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            head <= 0;
            tail <= 0;
        end else begin
            // 入队操作 - 使用位操作代替模运算
            if (cmd_push && !queue_full) begin
                cmd_queue[head] <= cmd_data;
                head <= (head + 1'b1) & (QUEUE_DEPTH-1);
            end
            
            // 出队操作 - 优化条件判断
            if (transfer_complete_stage3 && !queue_empty) begin
                tail <= (tail + 1'b1) & (QUEUE_DEPTH-1);
            end
        end
    end
    
    // 流水线阶段1: 命令获取和解码 - 优化状态机
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state_stage1 <= IDLE;
            current_cmd_stage1 <= 8'h00;
            bit_cnt_stage1 <= 3'b000;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b0;
            
            case (state_stage1)
                IDLE: begin
                    if (!queue_empty) begin
                        state_stage1 <= START;
                        current_cmd_stage1 <= cmd_queue[tail];
                        valid_stage1 <= 1'b1;
                    end
                end
                
                START: begin
                    state_stage1 <= ADDR;
                    bit_cnt_stage1 <= 3'b000;
                    valid_stage1 <= 1'b1;
                end
                
                ADDR: begin
                    valid_stage1 <= 1'b1;
                    if (bit_cnt_stage1 == 3'b111) begin
                        state_stage1 <= ACK1;
                        bit_cnt_stage1 <= 3'b000;
                    end else begin
                        bit_cnt_stage1 <= bit_cnt_stage1 + 1'b1;
                    end
                end
                
                ACK1: begin
                    state_stage1 <= TX_DATA;
                    bit_cnt_stage1 <= 3'b000;
                    valid_stage1 <= 1'b1;
                end
                
                TX_DATA: begin
                    valid_stage1 <= 1'b1;
                    if (bit_cnt_stage1 == 3'b111) begin
                        state_stage1 <= ACK2;
                        bit_cnt_stage1 <= 3'b000;
                    end else begin
                        bit_cnt_stage1 <= bit_cnt_stage1 + 1'b1;
                    end
                end
                
                ACK2: begin
                    state_stage1 <= STOP;
                    valid_stage1 <= 1'b1;
                end
                
                STOP: begin
                    state_stage1 <= IDLE;
                    valid_stage1 <= 1'b1;
                end
                
                default: state_stage1 <= IDLE;
            endcase
        end
    end
    
    // 流水线阶段2: I2C信号生成 - 优化信号生成逻辑
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state_stage2 <= IDLE;
            current_cmd_stage2 <= 8'h00;
            bit_cnt_stage2 <= 3'b000;
            valid_stage2 <= 1'b0;
            sda_out_stage2 <= 1'b1;
            scl_out_stage2 <= 1'b1;
            sda_en_stage2 <= 1'b1;
        end else begin
            // 数据寄存
            state_stage2 <= state_stage1;
            current_cmd_stage2 <= current_cmd_stage1;
            bit_cnt_stage2 <= bit_cnt_stage1;
            valid_stage2 <= valid_stage1;
            
            // 默认值设置 - 减少冗余逻辑
            if (state_stage1 == IDLE) begin
                sda_out_stage2 <= 1'b1;
                scl_out_stage2 <= 1'b1;
                sda_en_stage2 <= 1'b1;
            end else if (state_stage1 == START) begin
                sda_out_stage2 <= 1'b0;
                scl_out_stage2 <= 1'b1;
                sda_en_stage2 <= 1'b0;
            end else if (state_stage1 == ADDR || state_stage1 == TX_DATA) begin
                // 合并相似状态的处理逻辑
                scl_out_stage2 <= !scl_out_stage2;
                if (scl_out_stage2 == 1'b0) begin
                    // 使用移位操作替代索引计算
                    sda_out_stage2 <= (current_cmd_stage1 >> (3'h7 - bit_cnt_stage1)) & 1'b1;
                    sda_en_stage2 <= 1'b0;
                end
            end else if (state_stage1 == ACK1 || state_stage1 == ACK2) begin
                // 合并ACK状态处理
                scl_out_stage2 <= !scl_out_stage2;
                sda_en_stage2 <= 1'b1;
            end else if (state_stage1 == STOP) begin
                if (scl_out_stage2 == 1'b0) begin
                    scl_out_stage2 <= 1'b1;
                    sda_out_stage2 <= 1'b0;
                    sda_en_stage2 <= 1'b0;
                end else begin
                    sda_out_stage2 <= 1'b1;
                end
            end
        end
    end
    
    // 流水线阶段3: I2C总线驱动和状态返回 - 优化传输完成检测
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state_stage3 <= IDLE;
            sda_out <= 1'b1;
            scl_out <= 1'b1;
            sda_en <= 1'b1;
            valid_stage3 <= 1'b0;
            transfer_complete_stage3 <= 1'b0;
            transfer_done <= 1'b0;
            rx_data <= 8'h00;
        end else begin
            // 将阶段2的控制信号传递到总线驱动
            state_stage3 <= state_stage2;
            sda_out <= sda_out_stage2;
            scl_out <= scl_out_stage2;
            sda_en <= sda_en_stage2;
            valid_stage3 <= valid_stage2;
            
            // 高效检测STOP完成状态 - 使用状态比较而非多条件
            transfer_complete_stage3 <= valid_stage2 && 
                                       (state_stage2 == STOP) && 
                                       scl_out_stage2 && 
                                       sda_out_stage2;
            
            // 传输完成标志 - 直接传递而非额外条件检查
            transfer_done <= transfer_complete_stage3;
        end
    end
    
endmodule