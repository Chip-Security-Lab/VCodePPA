module UART_9Bit_Address #(
    parameter ADDRESS = 8'hFF
)(
    input  wire        clk,          // 添加时钟信号
    input  wire        rst_n,        // 添加复位信号
    input  wire        addr_mode_en, // 地址模式使能
    output reg         frame_match,
    input  wire        rx_start,     // 添加开始信号
    input  wire        rx_bit9,      // 添加第9位信号
    input  wire        rx_done,      // 添加结束信号
    input  wire [7:0]  rx_data,      // 添加接收数据
    // 标准接口增加第9位
    input  wire [8:0]  tx_data_9bit,
    output reg  [8:0]  rx_data_9bit
);
// 地址识别状态机
localparam ADDR_IDLE = 0, ADDR_CHECK = 1, DATA_PHASE = 2;
reg [1:0] state;

// 地址匹配寄存器
reg [7:0] target_addr;
reg addr_flag;

// 状态机实现
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= ADDR_IDLE;
        frame_match <= 0;
        target_addr <= ADDRESS; // 使用参数初始化
        rx_data_9bit <= 0;
        addr_flag <= 0;
    end else if (addr_mode_en) begin
        case(state)
            ADDR_IDLE: 
                if (rx_start && rx_bit9) begin
                    state <= ADDR_CHECK;
                    frame_match <= 0;
                end
            
            ADDR_CHECK:
                if (rx_done) begin
                    frame_match <= (rx_data == target_addr);
                    state <= frame_match ? DATA_PHASE : ADDR_IDLE;
                end
            
            DATA_PHASE:
                if (rx_done) begin
                    rx_data_9bit <= {rx_bit9, rx_data};
                    if (!rx_bit9) // 非地址帧
                        state <= DATA_PHASE;
                    else // 新的地址帧
                        state <= ADDR_CHECK;
                end
                
            default: state <= ADDR_IDLE;
        endcase
    end
end

// 数据位扩展逻辑
wire [8:0] tx_packet;
assign tx_packet = {addr_flag, tx_data_9bit[7:0]};
endmodule