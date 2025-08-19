//SystemVerilog
// Top-level SPI Configurable Module with AXI4-Lite Interface
module SPI_Configurable_AXI4Lite #(
    parameter REG_FILE_SIZE = 8
)(
    input  wire         axi_aclk,
    input  wire         axi_aresetn,

    // AXI4-Lite Write Address Channel
    input  wire [7:0]   s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output reg          s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [15:0]  s_axi_wdata,
    input  wire [1:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output reg          s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg  [1:0]   s_axi_bresp,
    output reg          s_axi_bvalid,
    input  wire         s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [7:0]   s_axi_araddr,
    input  wire         s_axi_arvalid,
    output reg          s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg  [15:0]  s_axi_rdata,
    output reg  [1:0]   s_axi_rresp,
    output reg          s_axi_rvalid,
    input  wire         s_axi_rready,

    // SPI接口
    output wire         sclk,
    output wire         mosi,
    output wire         cs_n,
    input  wire         miso
);

    // Internal signals for configuration register outputs
    wire [7:0] clk_div_value;
    wire [3:0] data_width_value;
    wire [1:0] cpol_cpha_value;

    // AXI4-Lite to Register File interface signals
    reg              reg_wr_en;
    reg  [7:0]       reg_wr_addr;
    reg  [15:0]      reg_wr_data;
    reg              reg_rd_en;
    reg  [7:0]       reg_rd_addr;
    wire [15:0]      reg_rd_data;

    // AXI4-Lite Write FSM
    localparam [1:0] AXI_WR_IDLE = 2'd0,
                     AXI_WR_DATA = 2'd1,
                     AXI_WR_RESP = 2'd2;

    reg [1:0] axi_wr_state;

    // AXI4-Lite Read FSM
    localparam [1:0] AXI_RD_IDLE = 2'd0,
                     AXI_RD_DATA = 2'd1;

    reg [1:0] axi_rd_state;

    // Internal register read data latch
    reg [15:0] reg_rd_data_latch;

    // Write FSM
    always @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            axi_wr_state   <= AXI_WR_IDLE;
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= 2'b00;
            reg_wr_en      <= 1'b0;
            reg_wr_addr    <= 8'd0;
            reg_wr_data    <= 16'd0;
        end else begin
            reg_wr_en      <= 1'b0; // Default no write

            case (axi_wr_state)
                AXI_WR_IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready  <= 1'b1;
                    if (s_axi_awvalid && s_axi_wvalid) begin
                        // Accept address and data
                        s_axi_awready <= 1'b0;
                        s_axi_wready  <= 1'b0;
                        reg_wr_en     <= 1'b1;
                        reg_wr_addr   <= s_axi_awaddr[7:0];
                        // Handle byte enables (wstrb)
                        reg_wr_data[7:0]   <= s_axi_wstrb[0] ? s_axi_wdata[7:0]   : 8'b0;
                        reg_wr_data[15:8]  <= s_axi_wstrb[1] ? s_axi_wdata[15:8]  : 8'b0;
                        axi_wr_state       <= AXI_WR_RESP;
                    end
                end
                AXI_WR_RESP: begin
                    s_axi_bvalid <= 1'b1;
                    s_axi_bresp  <= 2'b00; // OKAY
                    if (s_axi_bready && s_axi_bvalid) begin
                        s_axi_bvalid   <= 1'b0;
                        s_axi_awready  <= 1'b1;
                        s_axi_wready   <= 1'b1;
                        axi_wr_state   <= AXI_WR_IDLE;
                    end
                end
                default: begin
                    axi_wr_state <= AXI_WR_IDLE;
                end
            endcase
        end
    end

    // Read FSM
    always @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            axi_rd_state   <= AXI_RD_IDLE;
            s_axi_arready  <= 1'b0;
            s_axi_rvalid   <= 1'b0;
            s_axi_rresp    <= 2'b00;
            s_axi_rdata    <= 16'd0;
            reg_rd_en      <= 1'b0;
            reg_rd_addr    <= 8'd0;
            reg_rd_data_latch <= 16'd0;
        end else begin
            reg_rd_en <= 1'b0; // Default no read

            case (axi_rd_state)
                AXI_RD_IDLE: begin
                    s_axi_arready <= 1'b1;
                    if (s_axi_arvalid && s_axi_arready) begin
                        s_axi_arready    <= 1'b0;
                        reg_rd_en        <= 1'b1;
                        reg_rd_addr      <= s_axi_araddr[7:0];
                        axi_rd_state     <= AXI_RD_DATA;
                    end
                end
                AXI_RD_DATA: begin
                    // Latch data from register file
                    reg_rd_data_latch <= reg_rd_data;
                    s_axi_rdata       <= reg_rd_data;
                    s_axi_rvalid      <= 1'b1;
                    s_axi_rresp       <= 2'b00; // OKAY
                    if (s_axi_rvalid && s_axi_rready) begin
                        s_axi_rvalid   <= 1'b0;
                        s_axi_arready  <= 1'b1;
                        axi_rd_state   <= AXI_RD_IDLE;
                    end
                end
                default: begin
                    axi_rd_state <= AXI_RD_IDLE;
                end
            endcase
        end
    end

    // 子模块1: 配置寄存器文件（AXI4-Lite接口映射）
    SPI_Config_RegFile_AXI #(
        .REG_FILE_SIZE(REG_FILE_SIZE)
    ) u_config_regfile_axi (
        .clk           (axi_aclk),
        .rst_n         (axi_aresetn),
        .axi_wr_en     (reg_wr_en),
        .axi_wr_addr   (reg_wr_addr),
        .axi_wr_data   (reg_wr_data),
        .axi_rd_en     (reg_rd_en),
        .axi_rd_addr   (reg_rd_addr),
        .axi_rd_data   (reg_rd_data),
        .clk_div_out   (clk_div_value),
        .data_width_out(data_width_value),
        .cpol_cpha_out (cpol_cpha_value)
    );

    // 子模块2: 动态时钟分频与CPOL控制
    SPI_ClockGen u_clock_gen (
        .clk          (axi_aclk),
        .rst_n        (axi_aresetn),
        .clk_div      (clk_div_value),
        .cpol_cpha    (cpol_cpha_value),
        .sclk_out     (sclk)
    );

    // 子模块3: SPI MOSI/CS控制（占位，便于日后扩展）
    SPI_IO_Default u_spi_io_default (
        .mosi_out (mosi),
        .cs_n_out (cs_n)
    );

    // miso输入未使用

endmodule

// -----------------------------------------------------------------------------
// 子模块: 配置寄存器文件（AXI4-Lite接口适配）
// -----------------------------------------------------------------------------
module SPI_Config_RegFile_AXI #(
    parameter REG_FILE_SIZE = 8
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        axi_wr_en,
    input  wire [7:0]  axi_wr_addr,
    input  wire [15:0] axi_wr_data,
    input  wire        axi_rd_en,
    input  wire [7:0]  axi_rd_addr,
    output reg  [15:0] axi_rd_data,
    output reg  [7:0]  clk_div_out,
    output reg  [3:0]  data_width_out,
    output reg  [1:0]  cpol_cpha_out
);
    reg [15:0] config_reg [0:REG_FILE_SIZE-1];
    integer i;

    // 写操作
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0; i<REG_FILE_SIZE; i=i+1)
                config_reg[i] <= 16'd0;
        end else if(axi_wr_en) begin
            config_reg[axi_wr_addr] <= axi_wr_data;
        end
    end

    // 读操作
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            axi_rd_data <= 16'd0;
        end else if(axi_rd_en) begin
            axi_rd_data <= config_reg[axi_rd_addr];
        end
    end

    // 寄存器参数映射输出
    always @(*) begin
        clk_div_out    = config_reg[0][7:0];
        data_width_out = config_reg[1][3:0];
        cpol_cpha_out  = config_reg[2][1:0];
    end
endmodule

// -----------------------------------------------------------------------------
// 子模块: 动态时钟分频与CPOL控制
// -----------------------------------------------------------------------------
module SPI_ClockGen (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] clk_div,
    input  wire [1:0] cpol_cpha,
    output wire       sclk_out
);
    reg [7:0] clk_counter;
    reg       sclk_int;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            clk_counter <= 8'd0;
            sclk_int    <= 1'b0;
        end else begin
            if(clk_counter >= clk_div) begin
                sclk_int    <= ~sclk_int;
                clk_counter <= 8'd0;
            end else begin
                clk_counter <= clk_counter + 1;
            end
        end
    end

    // CPOL控制
    assign sclk_out = cpol_cpha[1] ? ~sclk_int : sclk_int;

endmodule

// -----------------------------------------------------------------------------
// 子模块: 默认MOSI和CS_N输出（占位实现）
// -----------------------------------------------------------------------------
module SPI_IO_Default (
    output wire mosi_out,
    output wire cs_n_out
);
    assign mosi_out = 1'b0;
    assign cs_n_out = 1'b1;
endmodule