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
    parameter IDLE=0, SOF=1, ID=2, RTR=3, CONTROL=4, DATA=5, CRC=6, ACK=7, EOF=8;
    
    reg [3:0] state, next_state;
    reg [5:0] bit_count, next_bit_count;
    reg [5:0] bit_count_id_buf;    // 为ID逻辑添加专用缓冲
    reg [5:0] bit_count_ctrl_buf;  // 为控制路径添加专用缓冲
    reg [14:0] crc_reg, next_crc_reg;
    
    // 状态和控制信号的前级寄存器
    reg can_tx_pre;
    reg tx_done_pre;
    reg rx_done_pre;
    
    // ID信号的选择逻辑前级计算
    reg id_bit_value;
    reg id_transition_condition;
    
    // 添加流水线寄存器，分割组合逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_count <= 6'h00;
            crc_reg <= 15'h0000;
            can_tx <= 1'b1;
            tx_done <= 1'b0;
            rx_done <= 1'b0;
        end else begin
            state <= next_state;
            bit_count <= next_bit_count;
            crc_reg <= next_crc_reg;
            can_tx <= can_tx_pre;
            tx_done <= tx_done_pre;
            rx_done <= rx_done_pre;
        end
    end
    
    // 为高扇出的bit_count信号添加缓冲寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_count_id_buf <= 6'h00;
            bit_count_ctrl_buf <= 6'h00;
        end else begin
            bit_count_id_buf <= bit_count;
            bit_count_ctrl_buf <= bit_count;
        end
    end
    
    // ID位值的流水线预计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            id_bit_value <= 1'b0;
            id_transition_condition <= 1'b0;
        end else begin
            if (STD_ID) begin
                id_bit_value <= std_message_id[10-bit_count];
                id_transition_condition <= (bit_count == 10);
            end else begin
                id_bit_value <= ext_message_id[28-bit_count];
                id_transition_condition <= (bit_count == 28);
            end
        end
    end
    
    // 主状态机组合逻辑，已被分割为多个部分
    always @(*) begin
        // 默认值保持状态不变
        next_state = state;
        next_bit_count = bit_count;
        next_crc_reg = crc_reg;
        can_tx_pre = can_tx;
        tx_done_pre = tx_done;
        rx_done_pre = rx_done;
        
        case (state)
            IDLE: begin
                if (tx_start) begin
                    next_state = SOF;
                    can_tx_pre = 1'b0; // SOF is dominant bit
                    next_bit_count = 6'h00;
                    next_crc_reg = 15'h0000;
                end
            end
            
            SOF: begin
                next_state = ID;
                next_bit_count = 6'h00;
            end
            
            ID: begin
                // 使用预计算的ID位值和转换条件
                can_tx_pre = id_bit_value;
                
                if (id_transition_condition)
                    next_state = RTR;
                else
                    next_bit_count = bit_count + 1;
            end
            
            // 其他状态简化实现
            default: next_state = IDLE;
        endcase
    end
endmodule