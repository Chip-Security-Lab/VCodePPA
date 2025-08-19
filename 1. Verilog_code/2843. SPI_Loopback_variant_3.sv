//SystemVerilog
//IEEE 1364-2005 Verilog
module SPI_Loopback #(
    parameter PRBS_SEED = 32'h12345678
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        loopback_en,
    input  wire        external_loop,
    output reg         error_flag,
    output wire [7:0]  error_count,
    // SPI接口
    output wire        sclk,
    output wire        cs_n,
    inout  wire        mosi,
    inout  wire        miso
);

// SPI时钟生成
reg sclk_int;
always @(posedge clk or posedge rst) begin
    if(rst)
        sclk_int <= 1'b0;
    else
        sclk_int <= ~sclk_int;
end
assign sclk = sclk_int;

// 片选信号生成优化
reg cs_n_int;
always @(posedge clk or posedge rst) begin
    if(rst)
        cs_n_int <= 1'b1;
    else
        cs_n_int <= ~loopback_en;
end
assign cs_n = cs_n_int;

// PRBS寄存器与生成部分流水线切割
reg  [31:0] prbs_reg;
reg         prbs_feedback_pipe;
reg         prbs_bit_pipe;
wire        prbs_feedback;
wire        prbs_bit;

assign prbs_feedback = prbs_reg[3] ^ prbs_reg[5];
assign prbs_bit      = prbs_reg[0];

// 插入流水线寄存器减少反馈链路延迟
always @(posedge sclk_int or posedge cs_n_int) begin
    if(cs_n_int) begin
        prbs_reg          <= PRBS_SEED;
        prbs_feedback_pipe<= 1'b0;
        prbs_bit_pipe     <= 1'b0;
    end else begin
        prbs_feedback_pipe<= prbs_feedback;
        prbs_bit_pipe     <= prbs_bit;
        prbs_reg          <= {prbs_reg[30:0], prbs_feedback_pipe};
    end
end

// SPI数据寄存器与计数流水线切割
reg [7:0] tx_shift_reg;
reg [7:0] rx_shift_reg;
reg [3:0] bit_counter;

// 插入流水线寄存器，优化移位路径
reg [7:0] tx_shift_pipe;
reg [7:0] rx_shift_pipe;
reg [3:0] bit_counter_pipe;

always @(posedge sclk_int or posedge cs_n_int) begin
    if(cs_n_int) begin
        tx_shift_pipe   <= 8'd0;
        rx_shift_pipe   <= 8'd0;
        bit_counter_pipe<= 4'd0;
    end else begin
        tx_shift_pipe   <= {tx_shift_reg[6:0], prbs_bit_pipe};
        rx_shift_pipe   <= {rx_shift_reg[6:0], miso};
        bit_counter_pipe<= bit_counter + 1'b1;
    end
end

always @(posedge sclk_int or posedge cs_n_int) begin
    if(cs_n_int) begin
        tx_shift_reg  <= 8'd0;
        rx_shift_reg  <= 8'd0;
        bit_counter   <= 4'd0;
    end else begin
        tx_shift_reg  <= tx_shift_pipe;
        rx_shift_reg  <= rx_shift_pipe;
        bit_counter   <= bit_counter_pipe;
    end
end

// 回环逻辑平衡与拆分
wire      mosi_int;
wire      miso_int;
wire      loopback_path_sel;
wire      external_path_sel;

assign loopback_path_sel  = loopback_en & ~external_loop;
assign external_path_sel  = external_loop;
assign mosi_int           = loopback_path_sel ? prbs_bit_pipe : 1'bz;
assign miso_int           = 1'bz; // miso_int仅用于inout驱动

assign mosi = external_path_sel ? miso : mosi_int;
assign miso = loopback_path_sel ? mosi : 1'bz;

// 错误检测优化，插入流水线
reg        compare_enable;
reg        tx_rx_error;
reg        compare_enable_pipe;
reg        tx_rx_error_pipe;

always @(posedge sclk_int or posedge cs_n_int) begin
    if(cs_n_int) begin
        compare_enable      <= 1'b0;
        tx_rx_error        <= 1'b0;
        compare_enable_pipe <= 1'b0;
        tx_rx_error_pipe    <= 1'b0;
        error_flag         <= 1'b0;
    end else begin
        compare_enable      <= (bit_counter == 4'd6) && loopback_en;
        if(compare_enable)
            tx_rx_error    <= (tx_shift_reg != rx_shift_reg);
        compare_enable_pipe <= compare_enable;
        tx_rx_error_pipe    <= tx_rx_error;
        error_flag         <= compare_enable_pipe && tx_rx_error_pipe;
    end
end

// 错误计数器优化
reg [7:0] err_counter;
always @(posedge clk or posedge rst) begin
    if(rst)
        err_counter <= 8'd0;
    else if(error_flag)
        err_counter <= err_counter + 1'b1;
end
assign error_count = err_counter;

endmodule