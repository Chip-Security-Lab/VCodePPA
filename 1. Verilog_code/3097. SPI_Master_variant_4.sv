//SystemVerilog
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

    localparam IDLE = 1'b0, ACTIVE = 1'b1;
    reg current_state, next_state;
    
    reg [DATA_WIDTH-1:0] shift_reg;
    reg [4:0] bit_counter;
    reg sclk_int;
    reg mosi_reg;
    
    // 流水线寄存器
    reg [DATA_WIDTH-1:0] shift_reg_pipe;
    reg [4:0] bit_counter_pipe;
    reg mosi_reg_pipe;
    reg cs_pipe;
    reg busy_pipe;
    reg [DATA_WIDTH-1:0] rx_data_pipe;

    // 条件反相减法器相关信号
    reg [4:0] bit_counter_next;
    wire [4:0] bit_counter_inc;
    wire [4:0] bit_counter_comp;
    wire [4:0] bit_counter_sub;
    wire [4:0] bit_counter_sel;

    // 条件反相减法器实现
    assign bit_counter_inc = bit_counter + 1;
    assign bit_counter_comp = ~bit_counter_inc;
    assign bit_counter_sub = bit_counter_comp + 1;
    assign bit_counter_sel = (bit_counter < (DATA_WIDTH*2)) ? bit_counter_inc : bit_counter;

    // 时钟生成逻辑 - 第一阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            sclk_int <= CPOL;
            bit_counter <= 0;
            shift_reg <= 0;
            cs <= 1'b1;
            mosi_reg <= 1'b0;
            busy <= 0;
            
            shift_reg_pipe <= 0;
            bit_counter_pipe <= 0;
            mosi_reg_pipe <= 0;
            cs_pipe <= 1'b1;
            busy_pipe <= 0;
            rx_data_pipe <= 0;
        end else begin
            current_state <= next_state;
            busy_pipe <= (current_state != IDLE);
            
            case(current_state)
                IDLE: begin
                    sclk_int <= CPOL;
                    bit_counter <= 0;
                    if (start) begin
                        shift_reg <= tx_data;
                        cs_pipe <= 1'b0;
                    end
                end
                ACTIVE: begin
                    if (bit_counter < (DATA_WIDTH*2)) begin
                        sclk_int <= ~sclk_int;
                        
                        if ((CPHA == 0 && sclk_int == 1'b0) || (CPHA == 1 && sclk_int == 1'b1)) begin
                            shift_reg_pipe <= {shift_reg[DATA_WIDTH-2:0], miso};
                            bit_counter_pipe <= bit_counter_sel;
                        end 
                        else if ((CPHA == 0 && sclk_int == 1'b1) || (CPHA == 1 && sclk_int == 1'b0)) begin
                            mosi_reg_pipe <= shift_reg[DATA_WIDTH-1];
                            bit_counter_pipe <= bit_counter_sel;
                        end
                    end else begin
                        rx_data_pipe <= shift_reg;
                        cs_pipe <= 1'b1;
                    end
                end
                default: ;
            endcase
        end
    end

    // 流水线第二阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= 0;
            busy <= 0;
            cs <= 1'b1;
            mosi_reg <= 0;
        end else begin
            shift_reg <= shift_reg_pipe;
            bit_counter <= bit_counter_pipe;
            mosi_reg <= mosi_reg_pipe;
            cs <= cs_pipe;
            busy <= busy_pipe;
            rx_data <= rx_data_pipe;
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