//SystemVerilog
module can_codec #(parameter STD_ID = 1) // 1=standard ID, 0=extended ID
(
    input wire clk, rst_n,
    input wire can_rx, tx_start,
    input wire [10:0] std_message_id,
    input wire [28:0] ext_message_id,
    input wire [7:0] tx_data_0, tx_data_1, tx_data_2, tx_data_3,
    input wire [7:0] tx_data_4, tx_data_5, tx_data_6, tx_data_7,
    input wire [3:0] data_length,
    output reg can_tx, tx_done, rx_done,
    output reg [10:0] rx_std_id,
    output reg [28:0] rx_ext_id,
    output reg [7:0] rx_data_0, rx_data_1, rx_data_2, rx_data_3,
    output reg [7:0] rx_data_4, rx_data_5, rx_data_6, rx_data_7,
    output reg [3:0] rx_length
);
    // 状态编码优化：使用单热码减少状态解码逻辑深度
    localparam [8:0] IDLE     = 9'b000000001,
                     SOF      = 9'b000000010,
                     ID       = 9'b000000100,
                     RTR      = 9'b000001000,
                     CONTROL  = 9'b000010000,
                     DATA     = 9'b000100000,
                     CRC      = 9'b001000000,
                     ACK      = 9'b010000000,
                     EOF      = 9'b100000000;
                     
    reg [8:0] state, next_state;
    reg [5:0] bit_count, next_bit_count;
    reg [14:0] crc_reg, next_crc_reg;
    reg next_can_tx;
    
    // ID缓存寄存器 - 预先选择ID，减少关键路径延迟
    reg [28:0] active_id;
    
    // 提前生成状态转换信号，减少关键路径
    wire is_idle_state = (state == IDLE);
    wire is_id_state = (state == ID);
    wire is_eof_state = (state == EOF);
    wire is_sof_state = (state == SOF);
    wire is_data_state = (state == DATA);
    wire transition_to_idle = (next_state == IDLE);
    
    // CRC相关信号优化
    wire update_crc;
    wire crc_input_bit;
    
    // 位计数器终止条件预计算
    wire std_id_complete = STD_ID && (bit_count == 10);
    wire ext_id_complete = !STD_ID && (bit_count == 28);
    wire id_complete = std_id_complete || ext_id_complete;
    
    // 状态寄存器更新 - 保持单一always块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_count <= 6'h00;
            crc_reg <= 15'h0000;
            active_id <= 29'h0;
        end else begin
            state <= next_state;
            bit_count <= next_bit_count;
            crc_reg <= next_crc_reg;
            
            // 在IDLE状态预先选择活动ID，减少ID状态中的关键路径
            if (is_idle_state && tx_start) begin
                active_id <= STD_ID ? {18'h0, std_message_id} : ext_message_id;
            end
        end
    end
    
    // 输出寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            can_tx <= 1'b1; // Recessive idle state
            tx_done <= 1'b0;
            rx_done <= 1'b0;
        end else begin
            can_tx <= next_can_tx;
            
            // 使用预计算的状态信号简化条件
            if (is_eof_state && transition_to_idle)
                tx_done <= 1'b1;
            else if (is_idle_state && next_state == SOF)
                tx_done <= 1'b0;
                
            // rx_done逻辑可以在这里添加，根据实际需求
        end
    end
    
    // 接收数据寄存器更新 (简化版，实际实现需要根据接收逻辑完善)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_std_id <= 11'h0;
            rx_ext_id <= 29'h0;
            rx_data_0 <= 8'h0; rx_data_1 <= 8'h0;
            rx_data_2 <= 8'h0; rx_data_3 <= 8'h0;
            rx_data_4 <= 8'h0; rx_data_5 <= 8'h0;
            rx_data_6 <= 8'h0; rx_data_7 <= 8'h0;
            rx_length <= 4'h0;
        end
        // 接收逻辑在下面实现（此处简化省略）
    end
    
    // 下一状态和控制信号组合逻辑 - 分离为多个并行逻辑块减少深度
    always @(*) begin
        // 默认保持当前值以避免锁存器
        next_state = state;
        next_bit_count = bit_count;
        next_crc_reg = crc_reg;
        next_can_tx = can_tx;
        
        case (1'b1) // 单热码状态机的优化写法
            is_idle_state: begin
                next_can_tx = 1'b1; // Recessive idle state
                if (tx_start) begin
                    next_state = SOF;
                    next_can_tx = 1'b0; // SOF is dominant bit
                    next_bit_count = 6'h00;
                    next_crc_reg = 15'h0000;
                end
            end
            
            is_sof_state: begin
                next_state = ID;
                next_bit_count = 6'h00;
            end
            
            is_id_state: begin
                // 简化的ID位选择逻辑，使用预先选择的ID
                next_can_tx = STD_ID ? active_id[10-bit_count] : active_id[28-bit_count];
                
                if (id_complete)
                    next_state = RTR;
                else
                    next_bit_count = bit_count + 1'b1;
            end
            
            (state == RTR): begin
                // RTR位逻辑
                next_state = CONTROL;
                next_bit_count = 6'h00;
            end
            
            (state == CONTROL): begin
                // 控制字段逻辑
                next_state = DATA;
                next_bit_count = 6'h00;
            end
            
            is_data_state: begin
                // 数据字段逻辑
                // 简化实现
                next_state = CRC;
                next_bit_count = 6'h00;
            end
            
            (state == CRC): begin
                // CRC字段逻辑
                next_state = ACK;
            end
            
            (state == ACK): begin
                // ACK字段逻辑
                next_state = EOF;
            end
            
            is_eof_state: begin
                // EOF字段逻辑
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // CRC计算相关信号生成 - 分离逻辑减少路径深度
    assign update_crc = (state == ID) || (state == RTR) || (state == CONTROL) || (state == DATA);
    assign crc_input_bit = can_tx;
    
    // CRC计算逻辑 - 优化为单独的always块
    wire crc_next = crc_reg[14] ^ crc_input_bit;
    wire [14:0] crc_shift = {crc_reg[13:0], crc_next};
    
    // CRC更新逻辑
    always @(*) begin
        if (update_crc) begin
            // 实际的CRC-15计算应使用正确的多项式
            next_crc_reg = crc_shift;
        end else begin
            next_crc_reg = crc_reg;
        end
    end
endmodule