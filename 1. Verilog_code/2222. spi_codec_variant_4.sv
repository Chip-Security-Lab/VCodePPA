//SystemVerilog
//IEEE 1364-2005 Verilog
module spi_codec #(parameter DATA_WIDTH = 8)
(
    input  wire                    clk_i,     // 系统时钟
    input  wire                    rst_ni,    // 低电平有效复位
    input  wire                    enable_i,  // 传输使能信号
    input  wire [DATA_WIDTH-1:0]   tx_data_i, // 发送数据
    input  wire                    miso_i,    // 主机输入从机输出
    output wire                    sclk_o,    // SPI时钟
    output wire                    cs_no,     // 片选信号(低电平有效)
    output wire                    mosi_o,    // 主机输出从机输入
    output reg  [DATA_WIDTH-1:0]   rx_data_o, // 接收数据
    output reg                     tx_done_o, // 发送完成指示
    output reg                     rx_done_o  // 接收完成指示
);
    // 常量和参数定义
    localparam MAX_COUNT = DATA_WIDTH;
    localparam CNT_WIDTH = $clog2(DATA_WIDTH+1);
    
    // 控制路径寄存器
    reg                     spi_active;       // SPI传输活跃状态
    reg                     sclk_enable;      // SPI时钟使能
    reg [CNT_WIDTH-1:0]     bit_counter;      // 位计数器
    
    // 输入缓冲寄存器 - 第一级流水线
    reg                     enable_i_d1;      // 缓冲的使能信号
    reg [DATA_WIDTH-1:0]    tx_data_i_d1;     // 缓冲的发送数据
    reg                     miso_i_d1;        // 缓冲的MISO信号
    
    // 数据路径寄存器
    reg [DATA_WIDTH-1:0]    tx_shift_reg;     // 发送移位寄存器
    reg [DATA_WIDTH-1:0]    rx_shift_reg;     // 接收移位寄存器
    reg [DATA_WIDTH-1:0]    rx_data_reg;      // 接收数据寄存器
    
    // 流水线阶段标志信号
    reg                     transfer_done;    // 传输完成指示
    
    // 控制状态信号
    wire                    start_transfer;   // 开始传输
    wire                    transfer_active;  // 传输活跃
    wire                    transfer_complete;// 传输完成
    
    // 控制信号生成 - 使用位比较提高效率
    assign start_transfer = enable_i_d1 && !spi_active;
    assign transfer_active = spi_active && (bit_counter < MAX_COUNT);
    assign transfer_complete = spi_active && (bit_counter == MAX_COUNT);
    
    // 输出信号生成
    assign sclk_o = enable_i_d1 & sclk_enable & clk_i;  // SPI时钟生成
    assign cs_no = ~spi_active;                         // 片选信号生成
    assign mosi_o = tx_shift_reg[DATA_WIDTH-1];         // MOSI数据输出
    
    //===================================================
    // 阶段1: 输入信号同步和缓冲
    //===================================================
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            enable_i_d1 <= 1'b0;
            tx_data_i_d1 <= {DATA_WIDTH{1'b0}};
            miso_i_d1 <= 1'b0;
        end else begin
            enable_i_d1 <= enable_i;
            tx_data_i_d1 <= tx_data_i;
            miso_i_d1 <= miso_i;
        end
    end
    
    //===================================================
    // 阶段2: 控制状态管理 - 分离控制路径
    //===================================================
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bit_counter <= {CNT_WIDTH{1'b0}};
            spi_active <= 1'b0;
            sclk_enable <= 1'b0;
            transfer_done <= 1'b0;
        end else begin
            if (start_transfer) begin
                // 开始新传输 - 初始化控制信号
                bit_counter <= {CNT_WIDTH{1'b0}};
                spi_active <= 1'b1;
                sclk_enable <= 1'b1;
                transfer_done <= 1'b0;
            end else if (transfer_active) begin
                // 传输进行中 - 增加计数器
                bit_counter <= bit_counter + 1'b1;
                transfer_done <= 1'b0;
            end else if (transfer_complete) begin
                // 传输完成 - 设置完成标志
                spi_active <= 1'b0;
                sclk_enable <= 1'b0;
                transfer_done <= 1'b1;
                bit_counter <= bit_counter + 1'b1;
            end else begin
                // 空闲状态 - 清除完成标志
                transfer_done <= 1'b0;
            end
        end
    end
    
    //===================================================
    // 阶段3: 数据路径处理 - 发送和接收移位寄存器
    //===================================================
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            tx_shift_reg <= {DATA_WIDTH{1'b0}};
            rx_shift_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            if (start_transfer) begin
                // 加载发送数据
                tx_shift_reg <= tx_data_i_d1;
            end else if (transfer_active) begin
                // 发送和接收数据位
                tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0};
                rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], miso_i_d1};
            end
        end
    end
    
    //===================================================
    // 阶段4: 输出寄存器更新 - 确保稳定的输出信号
    //===================================================
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rx_data_o <= {DATA_WIDTH{1'b0}};
            tx_done_o <= 1'b0;
            rx_done_o <= 1'b0;
        end else begin
            if (transfer_complete) begin
                rx_data_o <= rx_shift_reg;
            end
            
            // 分离完成标志生成
            tx_done_o <= transfer_done;
            rx_done_o <= transfer_done;
        end
    end
    
endmodule