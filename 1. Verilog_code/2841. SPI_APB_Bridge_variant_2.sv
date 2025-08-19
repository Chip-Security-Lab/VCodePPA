//SystemVerilog
module SPI_APB_Bridge #(
    parameter APB_ADDR_WIDTH = 16,
    parameter APB_DATA_WIDTH = 32
)(
    // APB接口
    input wire PCLK,
    input wire PRESETn,
    output reg PSEL,
    output reg PENABLE,
    output reg PWRITE,
    output reg [APB_ADDR_WIDTH-1:0] PADDR,
    output reg [APB_DATA_WIDTH-1:0] PWDATA,
    input wire [APB_DATA_WIDTH-1:0] PRDATA,
    input wire PREADY,
    // SPI接口
    input wire sclk,
    input wire cs_n,
    input wire mosi,
    output reg miso
);

// 状态定义
localparam STATE_IDLE  = 2'd0;
localparam STATE_CMD   = 2'd1;
localparam STATE_ADDR  = 2'd2;
localparam STATE_DATA  = 2'd3;

// SPI信号寄存器缓冲
reg [7:0] spi_shift_reg_int;
reg [7:0] spi_shift_reg_buf;
reg [4:0] spi_bit_count_int;
reg [4:0] spi_bit_count_buf;

// 高扇出b0信号缓冲寄存器
wire b0_int;
reg b0_buf;
assign b0_int = spi_shift_reg_int[7];

// APB状态机缓冲
reg [1:0] apb_state_int;
reg [1:0] apb_state_buf;

// PRDATA缓冲多级
reg [APB_DATA_WIDTH-1:0] prdata_buf0;
reg [APB_DATA_WIDTH-1:0] prdata_buf1;

// IDLE缓冲寄存器
wire is_idle_int;
reg is_idle_buf;
assign is_idle_int = (apb_state_int == STATE_IDLE);

// 数据缓冲
reg [APB_DATA_WIDTH-1:0] data_buffer_int;
reg [APB_DATA_WIDTH-1:0] data_buffer_buf;

// SPI接收逻辑，一级缓冲
always @(posedge sclk or posedge cs_n) begin
    if(cs_n) begin
        spi_shift_reg_int <= 8'h00;
        spi_bit_count_int <= 5'd0;
    end else begin
        spi_shift_reg_int <= {spi_shift_reg_int[6:0], mosi};
        if(spi_bit_count_int < 5'd23)
            spi_bit_count_int <= spi_bit_count_int + 1'b1;
        else
            spi_bit_count_int <= spi_bit_count_int; // saturate
    end
end

// SPI接收缓冲，二级缓冲
always @(posedge sclk or posedge cs_n) begin
    if(cs_n) begin
        spi_shift_reg_buf <= 8'h00;
        spi_bit_count_buf <= 5'd0;
    end else begin
        spi_shift_reg_buf <= spi_shift_reg_int;
        spi_bit_count_buf <= spi_bit_count_int;
    end
end

// b0缓冲寄存器
always @(posedge sclk or posedge cs_n) begin
    if(cs_n)
        b0_buf <= 1'b0;
    else
        b0_buf <= b0_int;
end

// APB状态机缓冲，一级
always @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn)
        apb_state_int <= STATE_IDLE;
    else
        apb_state_int <= apb_state_buf;
end

// APB状态机主逻辑
always @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn) begin
        apb_state_buf <= STATE_IDLE;
        PSEL <= 1'b0;
        PENABLE <= 1'b0;
        PWRITE <= 1'b0;
        PADDR <= {APB_ADDR_WIDTH{1'b0}};
        PWDATA <= {APB_DATA_WIDTH{1'b0}};
        data_buffer_int <= {APB_DATA_WIDTH{1'b0}};
    end else begin
        case(apb_state_int)
            STATE_IDLE: begin
                PENABLE <= 1'b0;
                PSEL <= 1'b0;
                if(spi_bit_count_buf == 5'd7) begin
                    PWRITE <= b0_buf;
                    apb_state_buf <= STATE_CMD;
                end else begin
                    apb_state_buf <= STATE_IDLE;
                end
            end
            STATE_CMD: begin
                if(spi_bit_count_buf == 5'd15) begin
                    PADDR <= {spi_shift_reg_buf, prdata_buf1[7:0]};
                    apb_state_buf <= STATE_ADDR;
                end else begin
                    apb_state_buf <= STATE_CMD;
                end
            end
            STATE_ADDR: begin
                if(spi_bit_count_buf == 5'd23) begin
                    PWDATA <= {spi_shift_reg_buf, prdata_buf1[23:0]};
                    PSEL <= 1'b1;
                    apb_state_buf <= STATE_DATA;
                end else begin
                    apb_state_buf <= STATE_ADDR;
                end
            end
            STATE_DATA: begin
                if(PREADY) begin
                    PENABLE <= 1'b1;
                    data_buffer_int <= prdata_buf1;
                    apb_state_buf <= STATE_IDLE;
                end else begin
                    apb_state_buf <= STATE_DATA;
                end
            end
            default: apb_state_buf <= STATE_IDLE;
        endcase
    end
end

// data_buffer缓冲寄存器
always @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn)
        data_buffer_buf <= {APB_DATA_WIDTH{1'b0}};
    else
        data_buffer_buf <= data_buffer_int;
end

// PRDATA多级缓冲
always @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn) begin
        prdata_buf0 <= {APB_DATA_WIDTH{1'b0}};
        prdata_buf1 <= {APB_DATA_WIDTH{1'b0}};
    end else begin
        prdata_buf0 <= PRDATA;
        prdata_buf1 <= prdata_buf0;
    end
end

// IDLE状态缓冲寄存器
always @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn)
        is_idle_buf <= 1'b1;
    else
        is_idle_buf <= is_idle_int;
end

// SPI发送逻辑，data_buffer_buf为高扇出缓冲
always @(negedge sclk or posedge cs_n) begin
    if(cs_n) begin
        miso <= 1'bz;
    end else begin
        if(spi_bit_count_buf >= 5'd0 && spi_bit_count_buf <= 5'd7)
            miso <= data_buffer_buf[31 - spi_bit_count_buf];
        else
            miso <= 1'bz;
    end
end

endmodule