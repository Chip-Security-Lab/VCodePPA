//SystemVerilog
module i2c_master_multiwidth #(
    parameter DATA_WIDTH = 8,  // Supports 8/16/32
    parameter PACKET_MODE = 0  // 0-single packet 1-continuous packet
)(
    input clk,
    input rst_async_n,         // Asynchronous reset
    input start_transfer,
    input [DATA_WIDTH-1:0] tx_payload,
    output reg [DATA_WIDTH-1:0] rx_payload,
    inout wire sda,
    output wire scl,
    output reg transfer_done
);
// Unique feature: Dynamic bit width + packet mode
localparam BYTE_COUNT = DATA_WIDTH/8;

// 寄存器移动：移除多余的缓冲寄存器，重新安排寄存器位置以优化时序
reg [DATA_WIDTH-1:0] tx_payload_reg;
reg [2:0] byte_counter;
reg [7:0] shift_reg[0:3]; // Size fixed to maximum of 4 bytes (32 bits)
reg [2:0] bit_cnt;
reg sda_oen;
reg sda_out;
reg [2:0] state, next_state;
reg clk_div;

// 前向缓冲寄存器减少扇出负载
reg start_transfer_buf;

// 后向位置移动的寄存器
reg scl_enable;
reg [7:0] shift_next[0:3];
reg byte_counter_next;

// Define states
localparam IDLE = 3'b000;
localparam START = 3'b001;
localparam TRANSFER = 3'b010;
localparam STOP = 3'b011;

// 寄存器更新逻辑 - 通过分离组合逻辑和时序逻辑优化关键路径
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n) begin
        tx_payload_reg <= 0;
        start_transfer_buf <= 0;
    end else begin
        tx_payload_reg <= tx_payload;
        start_transfer_buf <= start_transfer;
    end
end

// 三态控制优化
assign scl = scl_enable ? clk_div : 1'bz;
assign sda = sda_oen ? 1'bz : sda_out;

// 状态转换组合逻辑 - 分离组合逻辑减少关键路径
always @(*) begin
    next_state = state;
    scl_enable = (state != IDLE);
    
    case(state)
        IDLE: begin
            if (start_transfer_buf)
                next_state = START;
        end
        // Additional states would be implemented here
        default: next_state = IDLE;
    endcase
end

// 数据加载组合逻辑 - 移动到组合逻辑部分
always @(*) begin
    // 默认保持当前值
    for (int i = 0; i < 4; i = i + 1)
        shift_next[i] = shift_reg[i];
    byte_counter_next = byte_counter;
    
    // 根据当前状态决定下一个寄存器值
    if (state == IDLE && start_transfer_buf) begin
        if (DATA_WIDTH > 8)
            shift_next[0] = tx_payload_reg[7:0];
        else
            shift_next[0] = tx_payload_reg;
    end
    
    if (state == TRANSFER && bit_cnt == 3'd7) begin
        if (DATA_WIDTH > 8 && byte_counter < BYTE_COUNT-1) begin
            byte_counter_next = byte_counter + 1;
            case (byte_counter)
                0: shift_next[1] = tx_payload_reg[15:8];
                1: shift_next[2] = tx_payload_reg[23:16];
                2: shift_next[3] = tx_payload_reg[31:24];
                default: shift_next[0] = tx_payload_reg[7:0];
            endcase
        end
    end
end

// 主状态寄存器逻辑 - 优化后的时序路径
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n) begin
        state <= IDLE;
        byte_counter <= 0;
        bit_cnt <= 0;
        transfer_done <= 0;
        for (int i = 0; i < 4; i = i + 1)
            shift_reg[i] <= 0;
    end else begin
        state <= next_state;
        byte_counter <= byte_counter_next;
        
        // 更新shift_reg - 已从组合逻辑中获取值
        for (int i = 0; i < 4; i = i + 1)
            shift_reg[i] <= shift_next[i];
            
        // 其他寄存器更新逻辑在此处实现
    end
end

// 初始状态设置
initial begin
    byte_counter = 0;
    bit_cnt = 0;
    state = IDLE;
    next_state = IDLE;
    transfer_done = 0;
    rx_payload = 0;
    sda_oen = 1;
    sda_out = 1;
    clk_div = 1;
    scl_enable = 0;
    byte_counter_next = 0;
    start_transfer_buf = 0;
    tx_payload_reg = 0;
    
    for (int i = 0; i < 4; i = i + 1) begin
        shift_reg[i] = 0;
        shift_next[i] = 0;
    end
end

endmodule