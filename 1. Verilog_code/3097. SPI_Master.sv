module SPI_Master #(
    parameter DATA_WIDTH = 8,
    parameter CPOL = 0,
    parameter CPHA = 0
)(
    input clk, rst_n,
    input start,
    input [DATA_WIDTH-1:0] tx_data,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg busy,
    output sclk,
    output reg cs,
    output mosi,
    input miso
);
    // 使用localparam代替typedef enum
    localparam IDLE = 1'b0, ACTIVE = 1'b1;
    reg current_state, next_state;
    
    reg [DATA_WIDTH-1:0] shift_reg;
    reg [4:0] bit_counter; // 增加位宽以适应2倍的数据位数
    reg sclk_int;
    reg mosi_reg;

    // 时钟生成逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            sclk_int <= CPOL;
            bit_counter <= 0;
            shift_reg <= 0;
            rx_data <= 0;
            cs <= 1'b1;
            mosi_reg <= 1'b0;
            busy <= 0;
        end else begin
            current_state <= next_state;
            busy <= (current_state != IDLE);
            
            case(current_state)
                IDLE: begin
                    sclk_int <= CPOL;
                    bit_counter <= 0;
                    if (start) begin
                        shift_reg <= tx_data;
                        cs <= 1'b0;
                    end
                end
                ACTIVE: begin
                    if (bit_counter < (DATA_WIDTH*2)) begin
                        sclk_int <= ~sclk_int;
                        
                        // 在适当时钟边沿采样/移位
                        if ((CPHA == 0 && sclk_int == 1'b0) || (CPHA == 1 && sclk_int == 1'b1)) begin
                            // 采样MISO
                            shift_reg <= {shift_reg[DATA_WIDTH-2:0], miso};
                            bit_counter <= bit_counter + 1;
                        end 
                        else if ((CPHA == 0 && sclk_int == 1'b1) || (CPHA == 1 && sclk_int == 1'b0)) begin
                            // 设置MOSI
                            mosi_reg <= shift_reg[DATA_WIDTH-1];
                            bit_counter <= bit_counter + 1;
                        end
                    end else begin
                        // 传输完成
                        rx_data <= shift_reg;
                        cs <= 1'b1;
                    end
                end
                default: ; // 默认不操作
            endcase
        end
    end

    // 状态转移逻辑
    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: if (start) next_state = ACTIVE;
            ACTIVE: if (bit_counter >= (DATA_WIDTH*2)) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    assign sclk = (current_state == ACTIVE) ? sclk_int : CPOL;
    assign mosi = mosi_reg;
endmodule