//SystemVerilog
module CAN_Controller #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 500_000
)(
    input clk, rst_n,
    input tx_req,
    input [63:0] tx_data,
    output reg tx_ready,
    input rx_line,
    output reg [63:0] rx_data,
    output reg rx_valid
);
    localparam BIT_TIME = CLK_FREQ / BAUD_RATE;
    
    localparam IDLE = 3'b000, SOF = 3'b001, ID_FIELD = 3'b010, 
             CTRL_FIELD = 3'b011, DATA_FIELD = 3'b100, 
             CRC_FIELD = 3'b101, ACK = 3'b110, EOF = 3'b111;
    
    reg [2:0] current_state, next_state;
    reg [2:0] next_state_buf;
    reg [15:0] bit_counter;
    reg [15:0] bit_counter_buf;
    reg [63:0] shift_reg;
    reg [63:0] shift_reg_buf;
    reg [6:0] stuff_counter;
    reg [14:0] crc;
    reg dominant_bit;
    reg sample_point;
    reg bit_count_enable;
    reg tx_active;

    // 位计数器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 0;
            bit_counter_buf <= 0;
        end else if (tx_active) begin
            if (bit_counter == BIT_TIME-1) begin
                bit_counter <= 0;
                bit_counter_buf <= 0;
            end else begin
                bit_counter <= bit_counter + 1;
                bit_counter_buf <= bit_counter + 1;
            end
        end else begin
            bit_counter <= 0;
            bit_counter_buf <= 0;
        end
    end

    // 采样点生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_point <= 0;
            bit_count_enable <= 0;
        end else begin
            sample_point <= (bit_counter == BIT_TIME-1) && tx_active;
            bit_count_enable <= tx_active;
        end
    end

    // 状态寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            next_state_buf <= IDLE;
        end else begin
            current_state <= next_state_buf;
            next_state_buf <= next_state;
        end
    end

    // 发送控制信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_ready <= 1;
            tx_active <= 0;
        end else begin
            if (current_state == IDLE) begin
                tx_ready <= 1;
                if (tx_req) begin
                    tx_active <= 1;
                    tx_ready <= 0;
                end
            end else if (current_state == EOF && sample_point && bit_counter_buf >= BIT_TIME * 7) begin
                tx_active <= 0;
                tx_ready <= 1;
            end
        end
    end

    // 移位寄存器控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 0;
            shift_reg_buf <= 0;
        end else begin
            if (current_state == IDLE && tx_req) begin
                shift_reg <= tx_data;
                shift_reg_buf <= tx_data;
            end else if (sample_point) begin
                case(current_state)
                    ID_FIELD, DATA_FIELD, CTRL_FIELD: begin
                        shift_reg <= {shift_reg_buf[62:0], 1'b0};
                        shift_reg_buf <= {shift_reg_buf[62:0], 1'b0};
                    end
                    default: ;
                endcase
            end
        end
    end

    // 位填充控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stuff_counter <= 0;
            dominant_bit <= 1;
        end else if (sample_point) begin
            case(current_state)
                SOF: begin
                    dominant_bit <= 0;
                    stuff_counter <= 1;
                end
                ID_FIELD: begin
                    if (dominant_bit == shift_reg_buf[63]) begin
                        stuff_counter <= stuff_counter + 1;
                        if (stuff_counter == 5) begin
                            dominant_bit <= ~dominant_bit;
                            stuff_counter <= 0;
                        end
                    end else begin
                        stuff_counter <= 1;
                    end
                end
                DATA_FIELD, CTRL_FIELD: begin
                    dominant_bit <= shift_reg_buf[63];
                end
                CRC_FIELD: begin
                    dominant_bit <= crc[14];
                end
                EOF: begin
                    dominant_bit <= 1;
                end
                default: ;
            endcase
        end
    end

    // CRC计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc <= 0;
        end else if (sample_point && current_state == CRC_FIELD) begin
            crc <= {crc[13:0], 1'b0};
        end
    end

    // 接收数据处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= 0;
            rx_valid <= 0;
        end else begin
            rx_valid <= 0;
        end
    end

    // 状态转移逻辑
    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: if (tx_req && tx_ready) next_state = SOF;
            SOF: if (sample_point) next_state = ID_FIELD;
            ID_FIELD: if (bit_counter_buf >= BIT_TIME * 11) next_state = CTRL_FIELD;
            CTRL_FIELD: if (bit_counter_buf >= BIT_TIME * 4) next_state = DATA_FIELD;
            DATA_FIELD: if (bit_counter_buf >= BIT_TIME * 64) next_state = CRC_FIELD;
            CRC_FIELD: if (bit_counter_buf >= BIT_TIME * 15) next_state = ACK;
            ACK: if (sample_point) next_state = EOF;
            EOF: if (bit_counter_buf >= BIT_TIME * 7) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
endmodule