module I2C_Controller #(
    parameter ADDR_WIDTH = 7
)(
    input clk, rst_n,
    input start,
    input [ADDR_WIDTH-1:0] dev_addr,
    input [7:0] data_tx,
    output reg [7:0] data_rx,
    output reg ack_error,
    inout sda,
    inout scl
);
    // 使用localparam代替typedef enum
    localparam IDLE = 3'b000, START = 3'b001, ADDR = 3'b010, 
             ACK1 = 3'b011, DATA = 3'b100, ACK2 = 3'b101, STOP = 3'b110;
    reg [2:0] current_state, next_state;
    
    reg sda_out, scl_out;
    reg [3:0] bit_counter;
    reg [7:0] shift_reg;
    reg rw_bit;
    reg sda_oe; // 添加输出使能控制

    // 三态缓冲实现
    assign sda = sda_oe ? 1'b0 : 1'bz; // 当sda_oe为1时输出低电平，否则高阻态
    assign scl = scl_out ? 1'bz : 1'b0; // 当scl_out为1时高阻态，否则输出低电平

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            scl_out <= 1'b1;
            sda_out <= 1'b1;
            sda_oe <= 1'b0; // 默认为高阻态
            bit_counter <= 0;
            shift_reg <= 0;
            data_rx <= 0;
            ack_error <= 0;
            rw_bit <= 0;
        end else begin
            current_state <= next_state;
            
            case(current_state)
                IDLE: begin
                    scl_out <= 1'b1;
                    sda_oe <= 1'b0; // 高阻态
                    if (start) begin
                        shift_reg <= {dev_addr, rw_bit};
                    end
                end
                START: begin
                    sda_oe <= 1'b1; // 产生START条件：SDA从高到低
                    scl_out <= 1'b1;
                end
                ADDR: begin
                    if (bit_counter < 8) begin
                        if (scl_out == 1'b0) begin
                            sda_oe <= ~shift_reg[7]; // 注意反转，因为sda_oe=1输出低电平
                            scl_out <= 1'b1; // 产生时钟上升沿
                        end else begin
                            scl_out <= 1'b0; // 产生时钟下降沿
                            shift_reg <= {shift_reg[6:0], 1'b0};
                            bit_counter <= bit_counter + 1;
                        end
                    end
                end
                ACK1: begin
                    if (scl_out == 1'b0) begin
                        sda_oe <= 1'b0; // 释放SDA线等待ACK
                        scl_out <= 1'b1;
                    end else begin
                        ack_error <= sda; // 采样SDA线
                        scl_out <= 1'b0;
                        bit_counter <= 0;
                        if (!rw_bit) shift_reg <= data_tx;
                    end
                end
                DATA: begin
                    if (bit_counter < 8) begin
                        if (scl_out == 1'b0) begin
                            sda_oe <= rw_bit ? 1'b0 : ~shift_reg[7];
                            scl_out <= 1'b1;
                        end else begin
                            if (rw_bit) shift_reg <= {shift_reg[6:0], sda};
                            scl_out <= 1'b0;
                            if (!rw_bit) shift_reg <= {shift_reg[6:0], 1'b0};
                            bit_counter <= bit_counter + 1;
                        end
                    end
                end
                ACK2: begin
                    if (scl_out == 1'b0) begin
                        sda_oe <= rw_bit ? 1'b1 : 1'b0; // 主机给出ACK或等待从机ACK
                        scl_out <= 1'b1;
                    end else begin
                        if (!rw_bit) ack_error <= sda;
                        scl_out <= 1'b0;
                        data_rx <= shift_reg;
                    end
                end
                STOP: begin
                    if (scl_out == 1'b0) begin
                        sda_oe <= 1'b1; // SDA先保持低
                        scl_out <= 1'b1;
                    end else begin
                        sda_oe <= 1'b0; // 然后拉高产生STOP条件
                    end
                end
                default: begin
                    scl_out <= 1'b1;
                    sda_oe <= 1'b0;
                end
            endcase
        end
    end

    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: if (start) next_state = START;
            START: next_state = ADDR;
            ADDR: if (bit_counter == 8) next_state = ACK1;
            ACK1: next_state = (rw_bit) ? DATA : DATA; // 为简化逻辑，统一为DATA
            DATA: if (bit_counter == 8) next_state = ACK2;
            ACK2: next_state = STOP;
            STOP: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
endmodule