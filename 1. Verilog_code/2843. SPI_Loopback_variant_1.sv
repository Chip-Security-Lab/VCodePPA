//SystemVerilog
module SPI_Loopback #(
    parameter PRBS_SEED = 32'h12345678
)(
    input clk,
    input rst,
    input loopback_en,
    input external_loop,
    output error_flag,
    output [7:0] error_count,
    output sclk,
    output cs_n,
    inout mosi,
    inout miso
);

    // SPI时钟和片选控制信号
    wire sclk_int;
    wire cs_n_int;

    // PRBS bit
    wire prbs_bit;

    // TX/RX数据与bit计数
    wire [7:0] tx_data;
    wire [7:0] rx_data;
    wire [3:0] bit_cnt;
    wire error_flag_int;

    // 片选和时钟生成子模块
    SPI_ClkCSGen u_clkcsgen (
        .clk        (clk),
        .rst        (rst),
        .loopback_en(loopback_en),
        .sclk_out   (sclk_int),
        .cs_n_out   (cs_n_int)
    );

    assign sclk = sclk_int;
    assign cs_n = cs_n_int;

    // PRBS 生成子模块
    SPI_PRBSGen #(
        .PRBS_SEED(PRBS_SEED)
    ) u_prbsgen (
        .clk        (sclk_int),
        .rst        (rst),
        .cs_n       (cs_n_int),
        .prbs_bit   (prbs_bit)
    );

    // SPI数据收发与错误检测子模块
    SPI_DataLoopback u_dataloop (
        .clk        (clk),
        .rst        (rst),
        .sclk       (sclk_int),
        .cs_n       (cs_n_int),
        .loopback_en(loopback_en),
        .external_loop(external_loop),
        .prbs_bit   (prbs_bit),
        .miso_wire  (miso),
        .mosi_wire  (mosi),
        .tx_data    (tx_data),
        .rx_data    (rx_data),
        .bit_cnt    (bit_cnt),
        .error_flag (error_flag_int)
    );

    assign error_flag = error_flag_int;

    // 错误计数器
    SPI_ErrorCounter u_errcnt (
        .clk        (clk),
        .rst        (rst),
        .error_flag (error_flag_int),
        .error_count(error_count)
    );

endmodule

//-----------------------------------------------------------------------------
// SPI_ClkCSGen
// 片选和时钟信号生成
//-----------------------------------------------------------------------------
module SPI_ClkCSGen (
    input  clk,
    input  rst,
    input  loopback_en,
    output reg sclk_out,
    output reg cs_n_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sclk_out <= 1'b0;
        end else begin
            sclk_out <= ~sclk_out;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            cs_n_out <= 1'b1;
        else
            cs_n_out <= ~loopback_en;
    end
endmodule

//-----------------------------------------------------------------------------
// SPI_PRBSGen
// PRBS 伪随机序列发生器
//-----------------------------------------------------------------------------
module SPI_PRBSGen #(
    parameter PRBS_SEED = 32'h12345678
)(
    input  clk,
    input  rst,
    input  cs_n,
    output prbs_bit
);
    reg [31:0] prbs_reg;
    assign prbs_bit = prbs_reg[0];

    always @(posedge clk or posedge rst) begin
        if (rst || cs_n)
            prbs_reg <= PRBS_SEED;
        else
            prbs_reg <= {prbs_reg[30:0], prbs_reg[3] ^ prbs_reg[5]};
    end
endmodule

//-----------------------------------------------------------------------------
// SPI_DataLoopback
// 数据环回与错误检测
//-----------------------------------------------------------------------------
module SPI_DataLoopback (
    input  clk,
    input  rst,
    input  sclk,
    input  cs_n,
    input  loopback_en,
    input  external_loop,
    input  prbs_bit,
    inout  mosi_wire,
    inout  miso_wire,
    output reg [7:0] tx_data,
    output reg [7:0] rx_data,
    output reg [3:0] bit_cnt,
    output reg error_flag
);

    reg error_flag_next;

    // 回环逻辑
    assign mosi_wire = (external_loop) ? miso_wire : (loopback_en ? prbs_bit : 1'bz);
    assign miso_wire = (loopback_en & ~external_loop) ? mosi_wire : 1'bz;

    always @(*) begin
        if (cs_n) begin
            error_flag_next = 1'b0;
        end else if ((bit_cnt == 4'd7) && loopback_en) begin
            error_flag_next = (tx_data != rx_data);
        end else begin
            error_flag_next = 1'b0;
        end
    end

    always @(posedge sclk or posedge rst) begin
        if (rst || cs_n) begin
            tx_data <= 8'b0;
            rx_data <= 8'b0;
            bit_cnt <= 4'b0;
            error_flag <= 1'b0;
        end else begin
            tx_data <= {tx_data[6:0], prbs_bit};
            rx_data <= {rx_data[6:0], miso_wire};
            bit_cnt <= bit_cnt + 1'b1;
            error_flag <= error_flag_next;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// SPI_ErrorCounter
// 错误计数器
//-----------------------------------------------------------------------------
module SPI_ErrorCounter (
    input  clk,
    input  rst,
    input  error_flag,
    output reg [7:0] error_count
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            error_count <= 8'd0;
        else if (error_flag)
            error_count <= error_count + 1'b1;
    end
endmodule