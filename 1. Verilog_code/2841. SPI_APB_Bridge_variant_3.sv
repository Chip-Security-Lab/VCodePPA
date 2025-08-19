//SystemVerilog
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

// SPI接收流水线寄存器
reg [7:0] spi_shift_reg_stage1, spi_shift_reg_stage2;
reg [1:0] bit_counter_stage1, bit_counter_stage2;
reg valid_spi_rx_stage1, valid_spi_rx_stage2, valid_spi_rx_stage3;
reg cs_n_stage1, cs_n_stage2;

// APB流水线寄存器
reg [2:0] apb_state_stage1, apb_state_stage2, apb_state_stage3;
reg [APB_ADDR_WIDTH-1:0] addr_buffer_stage1, addr_buffer_stage2;
reg [APB_DATA_WIDTH-1:0] wdata_buffer_stage1, wdata_buffer_stage2;
reg [APB_DATA_WIDTH-1:0] data_buffer_stage1, data_buffer_stage2, data_buffer_stage3;

reg PSEL_stage1, PSEL_stage2;
reg PENABLE_stage1, PENABLE_stage2;
reg PWRITE_stage1, PWRITE_stage2;
reg [APB_ADDR_WIDTH-1:0] PADDR_stage1, PADDR_stage2;
reg [APB_DATA_WIDTH-1:0] PWDATA_stage1, PWDATA_stage2;

reg [APB_DATA_WIDTH-1:0] prdata_latched_stage1, prdata_latched_stage2;

reg start_pipeline;
reg flush_pipeline;

// 控制信号
reg valid_apb_stage1, valid_apb_stage2, valid_apb_stage3;
reg flush_apb_stage1, flush_apb_stage2, flush_apb_stage3;

localparam IDLE = 3'd0, CMD = 3'd1, ADDR = 3'd2, DATA = 3'd3;

// SPI接收流水线
always @(posedge sclk or posedge cs_n) begin
    if (cs_n) begin
        spi_shift_reg_stage1 <= 8'h00;
        bit_counter_stage1 <= 2'd0;
        valid_spi_rx_stage1 <= 1'b0;
        cs_n_stage1 <= 1'b1;
    end else begin
        spi_shift_reg_stage1 <= {spi_shift_reg_stage1[6:0], mosi};
        bit_counter_stage1 <= bit_counter_stage1 + 2'd1;
        valid_spi_rx_stage1 <= 1'b1;
        cs_n_stage1 <= cs_n;
    end
end

always @(posedge sclk or posedge cs_n) begin
    if (cs_n) begin
        spi_shift_reg_stage2 <= 8'h00;
        bit_counter_stage2 <= 2'd0;
        valid_spi_rx_stage2 <= 1'b0;
        cs_n_stage2 <= 1'b1;
    end else begin
        spi_shift_reg_stage2 <= spi_shift_reg_stage1;
        bit_counter_stage2 <= bit_counter_stage1;
        valid_spi_rx_stage2 <= valid_spi_rx_stage1;
        cs_n_stage2 <= cs_n_stage1;
    end
end

always @(posedge sclk or posedge cs_n) begin
    if (cs_n) begin
        valid_spi_rx_stage3 <= 1'b0;
    end else begin
        valid_spi_rx_stage3 <= valid_spi_rx_stage2;
    end
end

// APB流水线控制
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        apb_state_stage1 <= IDLE;
        valid_apb_stage1 <= 1'b0;
        flush_apb_stage1 <= 1'b0;
        prdata_latched_stage1 <= {APB_DATA_WIDTH{1'b0}};
        addr_buffer_stage1 <= {APB_ADDR_WIDTH{1'b0}};
        wdata_buffer_stage1 <= {APB_DATA_WIDTH{1'b0}};
        data_buffer_stage1 <= {APB_DATA_WIDTH{1'b0}};
        PSEL_stage1 <= 1'b0;
        PENABLE_stage1 <= 1'b0;
        PWRITE_stage1 <= 1'b0;
        PADDR_stage1 <= {APB_ADDR_WIDTH{1'b0}};
        PWDATA_stage1 <= {APB_DATA_WIDTH{1'b0}};
    end else begin
        // Stage 1: 接收SPI数据并初步解码
        apb_state_stage1 <= apb_state_stage1;
        valid_apb_stage1 <= 1'b0;
        flush_apb_stage1 <= 1'b0;

        if (apb_state_stage1 == IDLE && bit_counter_stage2 == 2'd3 && valid_spi_rx_stage2) begin
            PWRITE_stage1 <= spi_shift_reg_stage2[7];
            apb_state_stage1 <= CMD;
            valid_apb_stage1 <= 1'b1;
        end else if (apb_state_stage1 == CMD && bit_counter_stage2 == 2'd3 && valid_spi_rx_stage2) begin
            addr_buffer_stage1 <= {spi_shift_reg_stage2, PRDATA[7:0]};
            apb_state_stage1 <= ADDR;
            valid_apb_stage1 <= 1'b1;
        end else if (apb_state_stage1 == ADDR && bit_counter_stage2 == 2'd3 && valid_spi_rx_stage2) begin
            wdata_buffer_stage1 <= {spi_shift_reg_stage2, PRDATA[23:0]};
            PSEL_stage1 <= 1'b1;
            apb_state_stage1 <= DATA;
            valid_apb_stage1 <= 1'b1;
        end else if (apb_state_stage1 == DATA && PREADY) begin
            PENABLE_stage1 <= 1'b1;
            data_buffer_stage1 <= PRDATA;
            apb_state_stage1 <= IDLE;
            PSEL_stage1 <= 1'b0;
            PENABLE_stage1 <= 1'b0;
            valid_apb_stage1 <= 1'b1;
        end
        // Pipeline flush
        if (flush_pipeline) begin
            apb_state_stage1 <= IDLE;
            valid_apb_stage1 <= 1'b0;
            flush_apb_stage1 <= 1'b1;
        end
    end
end

// APB流水线stage2
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        apb_state_stage2 <= IDLE;
        valid_apb_stage2 <= 1'b0;
        flush_apb_stage2 <= 1'b0;
        prdata_latched_stage2 <= {APB_DATA_WIDTH{1'b0}};
        addr_buffer_stage2 <= {APB_ADDR_WIDTH{1'b0}};
        wdata_buffer_stage2 <= {APB_DATA_WIDTH{1'b0}};
        data_buffer_stage2 <= {APB_DATA_WIDTH{1'b0}};
        PSEL_stage2 <= 1'b0;
        PENABLE_stage2 <= 1'b0;
        PWRITE_stage2 <= 1'b0;
        PADDR_stage2 <= {APB_ADDR_WIDTH{1'b0}};
        PWDATA_stage2 <= {APB_DATA_WIDTH{1'b0}};
    end else begin
        apb_state_stage2 <= apb_state_stage1;
        valid_apb_stage2 <= valid_apb_stage1;
        flush_apb_stage2 <= flush_apb_stage1;
        prdata_latched_stage2 <= PRDATA; // latch PRDATA for next stage if needed
        addr_buffer_stage2 <= addr_buffer_stage1;
        wdata_buffer_stage2 <= wdata_buffer_stage1;
        data_buffer_stage2 <= data_buffer_stage1;
        PSEL_stage2 <= PSEL_stage1;
        PENABLE_stage2 <= PENABLE_stage1;
        PWRITE_stage2 <= PWRITE_stage1;
        PADDR_stage2 <= PADDR_stage1;
        PWDATA_stage2 <= PWDATA_stage1;
    end
end

// APB流水线stage3
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        apb_state_stage3 <= IDLE;
        valid_apb_stage3 <= 1'b0;
        flush_apb_stage3 <= 1'b0;
        data_buffer_stage3 <= {APB_DATA_WIDTH{1'b0}};
    end else begin
        apb_state_stage3 <= apb_state_stage2;
        valid_apb_stage3 <= valid_apb_stage2;
        flush_apb_stage3 <= flush_apb_stage2;
        data_buffer_stage3 <= data_buffer_stage2;
    end
end

// 输出寄存器赋值
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        PSEL <= 1'b0;
        PENABLE <= 1'b0;
        PWRITE <= 1'b0;
        PADDR <= {APB_ADDR_WIDTH{1'b0}};
        PWDATA <= {APB_DATA_WIDTH{1'b0}};
    end else begin
        PSEL <= PSEL_stage2;
        PENABLE <= PENABLE_stage2;
        PWRITE <= PWRITE_stage2;
        PADDR <= addr_buffer_stage2;
        PWDATA <= wdata_buffer_stage2;
    end
end

// SPI发送流水线 - 输出MISO数据
reg [4:0] miso_bit_counter_stage1, miso_bit_counter_stage2;
reg [APB_DATA_WIDTH-1:0] miso_data_stage1, miso_data_stage2;
reg miso_valid_stage1, miso_valid_stage2;

always @(negedge sclk or posedge cs_n) begin
    if (cs_n) begin
        miso_bit_counter_stage1 <= 5'd0;
        miso_data_stage1 <= {APB_DATA_WIDTH{1'b0}};
        miso_valid_stage1 <= 1'b0;
    end else if (apb_state_stage3 == DATA && valid_apb_stage3) begin
        miso_data_stage1 <= data_buffer_stage3;
        miso_bit_counter_stage1 <= 5'd0;
        miso_valid_stage1 <= 1'b1;
    end else if (miso_valid_stage1) begin
        miso_bit_counter_stage1 <= miso_bit_counter_stage1 + 5'd1;
        miso_valid_stage1 <= miso_valid_stage1;
    end else begin
        miso_valid_stage1 <= 1'b0;
    end
end

always @(negedge sclk or posedge cs_n) begin
    if (cs_n) begin
        miso_bit_counter_stage2 <= 5'd0;
        miso_data_stage2 <= {APB_DATA_WIDTH{1'b0}};
        miso_valid_stage2 <= 1'b0;
    end else begin
        miso_bit_counter_stage2 <= miso_bit_counter_stage1;
        miso_data_stage2 <= miso_data_stage1;
        miso_valid_stage2 <= miso_valid_stage1;
    end
end

always @(negedge sclk or posedge cs_n) begin
    if (cs_n) begin
        miso <= 1'bz;
    end else if (miso_valid_stage2) begin
        miso <= miso_data_stage2[APB_DATA_WIDTH-1-miso_bit_counter_stage2];
    end else begin
        miso <= 1'bz;
    end
end

// 流水线启动和刷新逻辑
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        flush_pipeline <= 1'b0;
        start_pipeline <= 1'b0;
    end else begin
        if (cs_n) begin
            flush_pipeline <= 1'b1;
            start_pipeline <= 1'b0;
        end else if (bit_counter_stage2 == 2'd3 && !cs_n) begin
            start_pipeline <= 1'b1;
            flush_pipeline <= 1'b0;
        end else begin
            flush_pipeline <= 1'b0;
            start_pipeline <= 1'b0;
        end
    end
end

endmodule