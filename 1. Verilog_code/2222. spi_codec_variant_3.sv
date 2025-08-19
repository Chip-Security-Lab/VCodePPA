//SystemVerilog
module spi_codec #(parameter DATA_WIDTH = 8)
(
    input wire clk_i, rst_ni, enable_i,
    input wire [DATA_WIDTH-1:0] tx_data_i,
    input wire miso_i,
    output wire sclk_o, cs_no, mosi_o,
    output reg [DATA_WIDTH-1:0] rx_data_o,
    output reg tx_done_o, rx_done_o
);
    reg [$clog2(DATA_WIDTH):0] bit_counter;
    reg [DATA_WIDTH-1:0] tx_shift_reg, rx_shift_reg;
    reg spi_active, sclk_enable;
    
    // Buffered control signals to reduce fan-out
    reg spi_active_buf1, spi_active_buf2;
    reg sclk_enable_buf;
    reg enable_buf;
    
    // Clock buffering
    wire clk_buf;
    assign clk_buf = clk_i; // Clock buffer instantiation
    
    // Buffered output signals
    wire cs_n_int;
    
    // Buffered data signals
    reg [DATA_WIDTH-1:0] tx_shift_reg_buf;
    
    // Clock generation logic with reduced fan-out
    assign sclk_o = enable_buf & sclk_enable_buf ? clk_buf : 1'b0;
    assign cs_n_int = ~spi_active_buf1;
    assign cs_no = cs_n_int;
    assign mosi_o = tx_shift_reg_buf[DATA_WIDTH-1];
    
    // Buffer registers for high fan-out signals
    always @(posedge clk_buf or negedge rst_ni) begin
        if (!rst_ni) begin
            spi_active_buf1 <= 1'b0;
            spi_active_buf2 <= 1'b0;
            sclk_enable_buf <= 1'b0;
            enable_buf <= 1'b0;
            tx_shift_reg_buf <= 0;
        end else begin
            spi_active_buf1 <= spi_active;
            spi_active_buf2 <= spi_active;
            sclk_enable_buf <= sclk_enable;
            enable_buf <= enable_i;
            tx_shift_reg_buf <= tx_shift_reg;
        end
    end
    
    // 状态定义
    localparam SPI_STATE_IDLE = 2'b00;
    localparam SPI_STATE_ACTIVE = 2'b01; 
    localparam SPI_STATE_COMPLETE = 2'b10;
    
    // 状态提取
    reg [1:0] spi_state;
    
    always @(*) begin
        if (!spi_active && enable_buf)
            spi_state = SPI_STATE_IDLE;
        else if (spi_active && bit_counter < DATA_WIDTH)
            spi_state = SPI_STATE_ACTIVE;
        else if (bit_counter == DATA_WIDTH)
            spi_state = SPI_STATE_COMPLETE;
        else
            spi_state = 2'b11; // 默认状态，实际不会进入
    end
    
    always @(posedge clk_buf or negedge rst_ni) begin
        if (!rst_ni) begin
            bit_counter <= 0;
            spi_active <= 1'b0;
            sclk_enable <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            tx_done_o <= 1'b0;
            rx_done_o <= 1'b0;
            rx_data_o <= 0;
        end else begin
            case (spi_state)
                SPI_STATE_IDLE: begin
                    tx_shift_reg <= tx_data_i;
                    bit_counter <= 0;
                    spi_active <= 1'b1;
                    sclk_enable <= 1'b1;
                    tx_done_o <= 1'b0;
                    rx_done_o <= 1'b0;
                end
                
                SPI_STATE_ACTIVE: begin
                    // Data transmission logic
                    tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0};
                    rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], miso_i};
                    bit_counter <= bit_counter + 1;
                end
                
                SPI_STATE_COMPLETE: begin
                    // Transaction completion
                    spi_active <= 1'b0;
                    sclk_enable <= 1'b0;
                    rx_data_o <= rx_shift_reg;
                    tx_done_o <= 1'b1;
                    rx_done_o <= 1'b1;
                end
                
                default: begin
                    // 保持当前状态不变
                end
            endcase
        end
    end
endmodule