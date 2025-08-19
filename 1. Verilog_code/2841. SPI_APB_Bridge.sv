module SPI_APB_Bridge #(
    parameter APB_ADDR_WIDTH = 16,
    parameter APB_DATA_WIDTH = 32
)(
    // APB接口
    input PCLK,
    input PRESETn,
    output reg PSEL,
    output reg PENABLE,
    output reg PWRITE,
    output reg [APB_ADDR_WIDTH-1:0] PADDR,
    output reg [APB_DATA_WIDTH-1:0] PWDATA,
    input [APB_DATA_WIDTH-1:0] PRDATA,
    input PREADY,
    // SPI接口
    input sclk,
    input cs_n,
    input mosi,
    output reg miso
);

reg [7:0] spi_shift_reg;
reg [2:0] apb_state;
reg [1:0] bit_counter;
reg [APB_DATA_WIDTH-1:0] data_buffer;

localparam IDLE = 0, CMD = 1, ADDR = 2, DATA = 3;

// SPI接收逻辑
always @(posedge sclk or posedge cs_n) begin
    if(cs_n) begin
        spi_shift_reg <= 8'h00;
        bit_counter <= 0;
    end else begin
        spi_shift_reg <= {spi_shift_reg[6:0], mosi};
        bit_counter <= bit_counter + 1;
    end
end

// APB状态机
always @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn) begin
        apb_state <= IDLE;
        PSEL <= 0;
        PENABLE <= 0;
    end else begin
        case(apb_state)
        IDLE: 
            if(bit_counter == 7) begin
                PWRITE <= spi_shift_reg[7];
                apb_state <= CMD;
            end
        CMD: 
            if(bit_counter == 15) begin
                PADDR <= {spi_shift_reg, PRDATA[7:0]};
                apb_state <= ADDR;
            end
        ADDR: 
            if(bit_counter == 23) begin
                PWDATA <= {spi_shift_reg, PRDATA[23:0]};
                PSEL <= 1;
                apb_state <= DATA;
            end
        DATA: 
            if(PREADY) begin
                PENABLE <= 1;
                data_buffer <= PRDATA;
                apb_state <= IDLE;
            end
        endcase
    end
end

// SPI发送逻辑
always @(negedge sclk or posedge cs_n) begin
    if(cs_n) begin
        miso <= 1'bz;
    end else begin
        case(bit_counter)
        0: miso <= data_buffer[31];
        1: miso <= data_buffer[30];
        // ... 其他位
        7: miso <= data_buffer[24];
        endcase
    end
end
endmodule
