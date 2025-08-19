//SystemVerilog
module spi_multiple_slave #(
    parameter SLAVE_COUNT = 4,
    parameter DATA_WIDTH = 8
)(
    input clk, rst_n,
    input [DATA_WIDTH-1:0] tx_data,
    input [$clog2(SLAVE_COUNT)-1:0] slave_select,
    input start_transfer,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg transfer_done,
    
    output spi_clk,
    output reg [SLAVE_COUNT-1:0] spi_cs_n,
    output spi_mosi,
    input [SLAVE_COUNT-1:0] spi_miso
);

    // 一级缓冲寄存器
    reg [DATA_WIDTH-1:0] shift_reg_buf1;
    reg [$clog2(DATA_WIDTH):0] bit_count_buf1;
    reg b0_buf1;

    // 二级缓冲寄存器
    reg [DATA_WIDTH-1:0] shift_reg_buf2;
    reg [$clog2(DATA_WIDTH):0] bit_count_buf2;
    reg b0_buf2;

    reg [DATA_WIDTH-1:0] shift_reg;
    reg [$clog2(DATA_WIDTH):0] bit_count;
    reg busy, spi_clk_en;
    wire active_miso;
    reg b0;

    assign spi_clk = busy ? clk : 1'b0;
    assign spi_mosi = shift_reg_buf2[DATA_WIDTH-1];
    assign active_miso = spi_miso[slave_select];

    // shift_reg 扇出缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_buf1 <= {DATA_WIDTH{1'b0}};
        end else begin
            shift_reg_buf1 <= shift_reg;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_buf2 <= {DATA_WIDTH{1'b0}};
        end else begin
            shift_reg_buf2 <= shift_reg_buf1;
        end
    end

    // bit_count 扇出缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_count_buf1 <= {($clog2(DATA_WIDTH)+1){1'b0}};
        end else begin
            bit_count_buf1 <= bit_count;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_count_buf2 <= {($clog2(DATA_WIDTH)+1){1'b0}};
        end else begin
            bit_count_buf2 <= bit_count_buf1;
        end
    end

    // b0 扇出缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b0_buf1 <= 1'b0;
        end else begin
            b0_buf1 <= b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b0_buf2 <= 1'b0;
        end else begin
            b0_buf2 <= b0_buf1;
        end
    end

    // 优化后的主时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg      <= {DATA_WIDTH{1'b0}};
            bit_count      <= {($clog2(DATA_WIDTH)+1){1'b0}};
            busy           <= 1'b0;
            transfer_done  <= 1'b0;
            spi_cs_n       <= {SLAVE_COUNT{1'b1}};
            rx_data        <= {DATA_WIDTH{1'b0}};
            b0             <= 1'b0;
        end else begin
            // 优先级顺序：启动传输 > 传输进行 > 空闲
            // 启动新的传输
            if (start_transfer && !busy) begin
                shift_reg     <= tx_data;
                bit_count     <= DATA_WIDTH;
                busy          <= 1'b1;
                transfer_done <= 1'b0;
                spi_cs_n      <= ~(1'b1 << slave_select);
                b0            <= 1'b0;
            end
            // 正在传输数据
            else if (busy) begin
                // 优化比较链，合并bit_count范围判断
                if (bit_count != 0) begin
                    if (!spi_clk) begin // rising edge of SPI clock
                        shift_reg <= {shift_reg[DATA_WIDTH-2:0], active_miso};
                        bit_count <= bit_count - 1;
                    end

                    // 优化比较：bit_count == 1 && spi_clk
                    if ((bit_count == 1) && spi_clk) begin
                        busy          <= 1'b0;
                        transfer_done <= 1'b1;
                        rx_data       <= {shift_reg[DATA_WIDTH-2:0], active_miso};
                        spi_cs_n      <= {SLAVE_COUNT{1'b1}};
                        b0            <= 1'b1;
                    end else begin
                        b0            <= 1'b0;
                        transfer_done <= 1'b0;
                    end
                end else begin
                    transfer_done <= 1'b0;
                    b0            <= 1'b0;
                end
            end
            // 空闲状态
            else begin
                transfer_done <= 1'b0;
                b0            <= 1'b0;
            end
        end
    end

endmodule