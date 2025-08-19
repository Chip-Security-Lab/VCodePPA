//SystemVerilog
//IEEE 1364-2005
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
    // 状态定义
    localparam IDLE=0, SOF=1, ID=2, RTR=3, CONTROL=4, DATA=5, CRC=6, ACK=7, EOF=8;
    
    // 寄存器定义
    reg [3:0] state, next_state;
    reg [5:0] bit_count, next_bit_count;
    reg [14:0] crc_reg, next_crc_reg;
    reg next_can_tx;
    reg next_tx_done, next_rx_done;
    wire id_complete;
    wire data_complete;
    wire crc_complete;
    wire eof_complete;
    
    // 比较逻辑优化
    assign id_complete = STD_ID ? (bit_count == 6'd10) : (bit_count == 6'd28);
    assign data_complete = (bit_count >= {data_length, 3'b000});
    assign crc_complete = (bit_count >= 6'd14);
    assign eof_complete = (bit_count >= 6'd6);
    
    // 状态更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_count <= 6'h00;
            crc_reg <= 15'h0000;
        end else begin
            state <= next_state;
            bit_count <= next_bit_count;
            crc_reg <= next_crc_reg;
        end
    end
    
    // 输出寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            can_tx <= 1'b1; // 复位时为隐性状态
            tx_done <= 1'b0;
            rx_done <= 1'b0;
        end else begin
            can_tx <= next_can_tx;
            tx_done <= next_tx_done;
            rx_done <= next_rx_done;
        end
    end
    
    // 状态和计数器转换逻辑
    always @(*) begin
        next_state = state;
        next_bit_count = bit_count;
        next_crc_reg = crc_reg;
        next_can_tx = can_tx;
        next_tx_done = tx_done;
        next_rx_done = rx_done;
        
        case (state)
            IDLE: begin
                if (tx_start) begin
                    next_state = SOF;
                    next_can_tx = 1'b0; // SOF是显性位
                    next_bit_count = 6'h00;
                    next_crc_reg = 15'h0000;
                end
            end
            
            SOF: begin
                next_state = ID;
                next_bit_count = 6'h00;
            end
            
            ID: begin
                if (STD_ID) begin
                    next_can_tx = std_message_id[10-bit_count];
                end else begin
                    next_can_tx = ext_message_id[28-bit_count];
                end
                
                if (id_complete) begin
                    next_state = RTR;
                    next_bit_count = 6'h00;
                end else begin
                    next_bit_count = bit_count + 1'b1;
                end
            end
            
            RTR: begin
                next_state = CONTROL;
                next_bit_count = 6'h00;
            end
            
            CONTROL: begin
                // 控制字段逻辑
                next_state = DATA;
                next_bit_count = 6'h00;
            end
            
            DATA: begin
                // 数据传输逻辑
                if (data_complete) begin
                    next_state = CRC;
                    next_bit_count = 6'h00;
                end else begin
                    next_bit_count = bit_count + 1'b1;
                end
            end
            
            CRC: begin
                // CRC计算和传输逻辑
                if (crc_complete) begin
                    next_state = ACK;
                    next_bit_count = 6'h00;
                end else begin
                    next_bit_count = bit_count + 1'b1;
                end
            end
            
            ACK: begin
                // ACK处理逻辑
                next_state = EOF;
                next_bit_count = 6'h00;
            end
            
            EOF: begin
                // EOF处理逻辑
                if (eof_complete) begin
                    next_state = IDLE;
                    next_tx_done = 1'b1;
                    next_can_tx = 1'b1; // 回到隐性空闲状态
                end else begin
                    next_bit_count = bit_count + 1'b1;
                end
            end
            
            default: begin
                next_state = IDLE;
                next_can_tx = 1'b1;
            end
        endcase
    end
    
    // CRC计算模块
    wire update_crc;
    wire crc_in;
    wire crc_feedback;
    
    // 优化CRC更新条件判断
    assign update_crc = (state >= ID && state <= DATA);
    assign crc_in = can_tx;
    assign crc_feedback = crc_reg[14] ^ crc_in;
    
    // CRC寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位逻辑在主状态机中
        end else if (update_crc) begin
            next_crc_reg = {crc_reg[13:0], crc_feedback};
            if (crc_feedback) begin
                next_crc_reg = next_crc_reg ^ 15'h4599;
            end
        end
    end
    
    // 接收数据处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_std_id <= 11'h0;
            rx_ext_id <= 29'h0;
            rx_data_0 <= 8'h0;
            rx_data_1 <= 8'h0;
            rx_data_2 <= 8'h0;
            rx_data_3 <= 8'h0;
            rx_data_4 <= 8'h0;
            rx_data_5 <= 8'h0;
            rx_data_6 <= 8'h0;
            rx_data_7 <= 8'h0;
            rx_length <= 4'h0;
        end else begin
            // 优化状态判断条件
            if (state == ID && can_rx == 1'b0) begin
                // 接收ID逻辑
                if (STD_ID && bit_count <= 10) begin
                    rx_std_id[10-bit_count] <= can_rx;
                end else if (!STD_ID && bit_count <= 28) begin
                    rx_ext_id[28-bit_count] <= can_rx;
                end
            end else if (state == CONTROL && bit_count <= 3) begin
                // 接收控制字段逻辑
                rx_length[3-bit_count] <= can_rx;
            end else if (state == DATA) begin
                // 优化接收数据逻辑，使用位测试提高效率
                case (bit_count[5:3])
                    3'b000: rx_data_0[7-bit_count[2:0]] <= can_rx;
                    3'b001: rx_data_1[7-bit_count[2:0]] <= can_rx;
                    3'b010: rx_data_2[7-bit_count[2:0]] <= can_rx;
                    3'b011: rx_data_3[7-bit_count[2:0]] <= can_rx;
                    3'b100: rx_data_4[7-bit_count[2:0]] <= can_rx;
                    3'b101: rx_data_5[7-bit_count[2:0]] <= can_rx;
                    3'b110: rx_data_6[7-bit_count[2:0]] <= can_rx;
                    3'b111: rx_data_7[7-bit_count[2:0]] <= can_rx;
                endcase
            end else if (state == EOF && eof_complete) begin
                next_rx_done = 1'b1;
            end
        end
    end
    
endmodule