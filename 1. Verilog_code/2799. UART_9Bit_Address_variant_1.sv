//SystemVerilog
module UART_9Bit_Address #(
    parameter ADDRESS = 8'hFF
)(
    input  wire        clk,           // 时钟信号
    input  wire        rst_n,         // 复位信号
    input  wire        addr_mode_en,  // 地址模式使能
    output reg         frame_match,
    input  wire        rx_start,      // 开始信号
    input  wire        rx_bit9,       // 第9位信号
    input  wire        rx_done,       // 结束信号
    input  wire [7:0]  rx_data,       // 接收数据
    input  wire [8:0]  tx_data_9bit,  // 发送数据（含9位）
    output reg  [8:0]  rx_data_9bit
);

// 地址识别状态机状态定义
localparam ADDR_IDLE  = 2'd0;
localparam ADDR_CHECK = 2'd1;
localparam DATA_PHASE = 2'd2;

//-----------------------------------------------------------------------------
// Forwarded input registers for synchronization
//-----------------------------------------------------------------------------
reg rx_start_sync, rx_bit9_sync, rx_done_sync;
reg [7:0] rx_data_sync;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_start_sync <= 1'b0;
        rx_bit9_sync  <= 1'b0;
        rx_done_sync  <= 1'b0;
        rx_data_sync  <= 8'b0;
    end else begin
        rx_start_sync <= rx_start;
        rx_bit9_sync  <= rx_bit9;
        rx_done_sync  <= rx_done;
        rx_data_sync  <= rx_data;
    end
end

//-----------------------------------------------------------------------------
// State registers
//-----------------------------------------------------------------------------
reg [1:0] curr_state;
reg [1:0] next_state_comb;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        curr_state <= ADDR_IDLE;
    end else if (addr_mode_en) begin
        curr_state <= next_state_comb;
    end
end

//-----------------------------------------------------------------------------
// Combinational next state logic
//-----------------------------------------------------------------------------
always @(*) begin
    next_state_comb = curr_state;
    case (curr_state)
        ADDR_IDLE: begin
            if (addr_mode_en && rx_start_sync && rx_bit9_sync)
                next_state_comb = ADDR_CHECK;
        end
        ADDR_CHECK: begin
            if (addr_mode_en && rx_done_sync) begin
                if (rx_data_sync == target_addr_reg)
                    next_state_comb = DATA_PHASE;
                else
                    next_state_comb = ADDR_IDLE;
            end
        end
        DATA_PHASE: begin
            if (addr_mode_en && rx_done_sync) begin
                if (rx_bit9_sync)
                    next_state_comb = ADDR_CHECK;
                else
                    next_state_comb = DATA_PHASE;
            end
        end
        default: next_state_comb = ADDR_IDLE;
    endcase
end

//-----------------------------------------------------------------------------
// Target address register
//-----------------------------------------------------------------------------
reg [7:0] target_addr_reg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        target_addr_reg <= ADDRESS;
end

//-----------------------------------------------------------------------------
// addr_flag register
//-----------------------------------------------------------------------------
reg addr_flag_reg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_flag_reg <= 1'b0;
    end else if (addr_mode_en) begin
        case (next_state_comb)
            ADDR_CHECK: addr_flag_reg <= 1'b1;
            DATA_PHASE: addr_flag_reg <= 1'b0;
            default:    addr_flag_reg <= addr_flag_reg;
        endcase
    end
end

//-----------------------------------------------------------------------------
// Combinational logic for frame_match_next
//-----------------------------------------------------------------------------
wire frame_match_next;
assign frame_match_next = (curr_state == ADDR_CHECK && rx_done_sync) ? (rx_data_sync == target_addr_reg) :
                          (curr_state == ADDR_IDLE && rx_start_sync && rx_bit9_sync) ? 1'b0 : frame_match;

//-----------------------------------------------------------------------------
// frame_match register logic
//-----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        frame_match <= 1'b0;
    end else if (addr_mode_en) begin
        frame_match <= frame_match_next;
    end
end

//-----------------------------------------------------------------------------
// Combinational logic for rx_data_9bit_next
//-----------------------------------------------------------------------------
wire [8:0] rx_data_9bit_next;
assign rx_data_9bit_next = (curr_state == DATA_PHASE && rx_done_sync) ? {rx_bit9_sync, rx_data_sync} : rx_data_9bit;

//-----------------------------------------------------------------------------
// rx_data_9bit register logic
//-----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_data_9bit <= 9'b0;
    end else if (addr_mode_en) begin
        rx_data_9bit <= rx_data_9bit_next;
    end
end

//-----------------------------------------------------------------------------
// Combinational logic for tx_packet
//-----------------------------------------------------------------------------
wire [8:0] tx_packet;
assign tx_packet = {addr_flag_reg, tx_data_9bit[7:0]};

endmodule