//SystemVerilog
module SPI_APB_Bridge #(
    parameter APB_ADDR_WIDTH = 16,
    parameter APB_DATA_WIDTH = 32
)(
    // APB接口
    input  wire                     PCLK,
    input  wire                     PRESETn,
    output reg                      PSEL,
    output reg                      PENABLE,
    output reg                      PWRITE,
    output reg  [APB_ADDR_WIDTH-1:0] PADDR,
    output reg  [APB_DATA_WIDTH-1:0] PWDATA,
    input  wire [APB_DATA_WIDTH-1:0] PRDATA,
    input  wire                     PREADY,
    // SPI接口
    input  wire                     sclk,
    input  wire                     cs_n,
    input  wire                     mosi,
    output reg                      miso
);

//---------------------
// SPI接收流水线Stage1: SPI移位寄存器
//---------------------
reg [7:0]  spi_shift_reg_stage1;
reg [2:0]  bit_counter_stage1;
reg        valid_spi_stage1;

always @(posedge sclk or posedge cs_n) begin
    if(cs_n) begin
        spi_shift_reg_stage1 <= 8'h00;
        bit_counter_stage1   <= 3'b000;
        valid_spi_stage1     <= 1'b0;
    end else begin
        spi_shift_reg_stage1 <= {spi_shift_reg_stage1[6:0], mosi};
        bit_counter_stage1   <= bit_counter_stage1 + 1'b1;
        valid_spi_stage1     <= 1'b1;
    end
end

//---------------------
// SPI接收流水线Stage2: 命令/地址/数据收集
//---------------------
reg [23:0] spi_cmd_addr_data_stage2;
reg [4:0]  bit_counter_stage2;
reg        valid_spi_stage2;

wire last_byte_stage2 = (bit_counter_stage2[2:0] == 3'd7);

always @(posedge sclk or posedge cs_n) begin
    if(cs_n) begin
        spi_cmd_addr_data_stage2 <= 24'd0;
        bit_counter_stage2       <= 5'd0;
        valid_spi_stage2         <= 1'b0;
    end else if(valid_spi_stage1) begin
        spi_cmd_addr_data_stage2 <= {spi_cmd_addr_data_stage2[15:0], spi_shift_reg_stage1};
        bit_counter_stage2       <= bit_counter_stage2 + 3'd1;
        valid_spi_stage2         <= last_byte_stage2;
    end else begin
        valid_spi_stage2         <= 1'b0;
    end
end

//---------------------
// SPI接收流水线Stage3: APB请求准备
//---------------------
reg [2:0]  apb_fsm_state;
reg        apb_PWRITE_stage3;
reg [APB_ADDR_WIDTH-1:0] apb_PADDR_stage3;
reg [APB_DATA_WIDTH-1:0] apb_PWDATA_stage3;
reg        valid_apb_stage3;

localparam IDLE_STAGE3  = 3'd0,
           CMD_STAGE3   = 3'd1,
           ADDR_STAGE3  = 3'd2,
           DATA_STAGE3  = 3'd3,
           WAIT_STAGE3  = 3'd4;

reg [7:0]  cmd_byte_buffer;
reg [15:0] addr_byte_buffer;
reg [7:0]  data_byte_buffer;

always @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn) begin
        apb_fsm_state      <= IDLE_STAGE3;
        apb_PWRITE_stage3  <= 1'b0;
        apb_PADDR_stage3   <= {APB_ADDR_WIDTH{1'b0}};
        apb_PWDATA_stage3  <= {APB_DATA_WIDTH{1'b0}};
        valid_apb_stage3   <= 1'b0;
        cmd_byte_buffer    <= 8'd0;
        addr_byte_buffer   <= 16'd0;
        data_byte_buffer   <= 8'd0;
    end else begin
        valid_apb_stage3 <= 1'b0;
        case (apb_fsm_state)
            IDLE_STAGE3: begin
                if(valid_spi_stage2 && (bit_counter_stage2 == 5'd8)) begin
                    cmd_byte_buffer   <= spi_cmd_addr_data_stage2[7:0];
                    apb_PWRITE_stage3 <= spi_cmd_addr_data_stage2[7];
                    apb_fsm_state     <= CMD_STAGE3;
                end
            end
            CMD_STAGE3: begin
                if(valid_spi_stage2 && (bit_counter_stage2 == 5'd16)) begin
                    addr_byte_buffer  <= spi_cmd_addr_data_stage2[15:0];
                    apb_PADDR_stage3  <= spi_cmd_addr_data_stage2[15:0];
                    apb_fsm_state     <= ADDR_STAGE3;
                end
            end
            ADDR_STAGE3: begin
                if(valid_spi_stage2 && (bit_counter_stage2 == 5'd24)) begin
                    data_byte_buffer  <= spi_cmd_addr_data_stage2[23:16];
                    apb_PWDATA_stage3 <= {spi_cmd_addr_data_stage2[23:16], spi_cmd_addr_data_stage2[15:0], 8'd0};
                    valid_apb_stage3  <= 1'b1;
                    apb_fsm_state     <= DATA_STAGE3;
                end
            end
            DATA_STAGE3: begin
                apb_fsm_state <= WAIT_STAGE3;
            end
            WAIT_STAGE3: begin
                apb_fsm_state <= IDLE_STAGE3;
            end
            default: apb_fsm_state <= IDLE_STAGE3;
        endcase
    end
end

//---------------------
// APB流水线Stage4: APB总线控制与数据采集
//---------------------
reg        apb_PSEL_stage4;
reg        apb_PENABLE_stage4;
reg        apb_PWRITE_stage4;
reg [APB_ADDR_WIDTH-1:0] apb_PADDR_stage4;
reg [APB_DATA_WIDTH-1:0] apb_PWDATA_stage4;
reg        apb_valid_stage4;
reg [APB_DATA_WIDTH-1:0] apb_PRDATA_stage4;

always @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn) begin
        apb_PSEL_stage4     <= 1'b0;
        apb_PENABLE_stage4  <= 1'b0;
        apb_PWRITE_stage4   <= 1'b0;
        apb_PADDR_stage4    <= {APB_ADDR_WIDTH{1'b0}};
        apb_PWDATA_stage4   <= {APB_DATA_WIDTH{1'b0}};
        apb_valid_stage4    <= 1'b0;
        apb_PRDATA_stage4   <= {APB_DATA_WIDTH{1'b0}};
    end else begin
        apb_PENABLE_stage4 <= 1'b0;
        apb_valid_stage4   <= 1'b0;
        if(valid_apb_stage3) begin
            apb_PSEL_stage4    <= 1'b1;
            apb_PWRITE_stage4  <= apb_PWRITE_stage3;
            apb_PADDR_stage4   <= apb_PADDR_stage3;
            apb_PWDATA_stage4  <= apb_PWDATA_stage3;
            apb_PENABLE_stage4 <= 1'b1;
        end else if(apb_PSEL_stage4 && PREADY) begin
            apb_PSEL_stage4    <= 1'b0;
            apb_PENABLE_stage4 <= 1'b0;
            apb_PRDATA_stage4  <= PRDATA;
            apb_valid_stage4   <= 1'b1;
        end
    end
end

//---------------------
// SPI发送流水线Stage5: 输出回APB数据
//---------------------
reg [APB_DATA_WIDTH-1:0] spi_data_out_buffer;
reg [2:0]                miso_bit_counter;
reg                      valid_miso_out;
reg                      cs_n_sync_stage5;

always @(posedge sclk or posedge cs_n) begin
    if(cs_n) begin
        spi_data_out_buffer   <= {APB_DATA_WIDTH{1'b0}};
        miso_bit_counter      <= 3'd0;
        valid_miso_out        <= 1'b0;
        cs_n_sync_stage5      <= 1'b1;
    end else begin
        cs_n_sync_stage5      <= 1'b0;
        if(apb_valid_stage4) begin
            spi_data_out_buffer <= apb_PRDATA_stage4;
            miso_bit_counter    <= 3'd0;
            valid_miso_out      <= 1'b1;
        end else if(valid_miso_out) begin
            miso_bit_counter <= miso_bit_counter + 1'b1;
            if(miso_bit_counter == 3'd7)
                valid_miso_out <= 1'b0;
        end
    end
end

always @(negedge sclk or posedge cs_n) begin
    if(cs_n) begin
        miso <= 1'bz;
    end else if(valid_miso_out) begin
        miso <= spi_data_out_buffer[31 - miso_bit_counter];
    end else begin
        miso <= 1'bz;
    end
end

//---------------------
// 顶层APB输出信号分配
//---------------------
always @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn) begin
        PSEL    <= 1'b0;
        PENABLE <= 1'b0;
        PWRITE  <= 1'b0;
        PADDR   <= {APB_ADDR_WIDTH{1'b0}};
        PWDATA  <= {APB_DATA_WIDTH{1'b0}};
    end else begin
        PSEL    <= apb_PSEL_stage4;
        PENABLE <= apb_PENABLE_stage4;
        PWRITE  <= apb_PWRITE_stage4;
        PADDR   <= apb_PADDR_stage4;
        PWDATA  <= apb_PWDATA_stage4;
    end
end

endmodule