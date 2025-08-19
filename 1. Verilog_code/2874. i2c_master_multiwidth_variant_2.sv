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
reg [2:0] byte_counter;
reg [7:0] shift_reg[0:3]; // Size fixed to maximum of 4 bytes (32 bits)
reg [7:0] next_shift_reg; // Pipeline register for next byte preparation
reg [2:0] bit_cnt;
reg sda_oen;
reg sda_out;
reg [2:0] state, next_state; // Pipelined state control
reg clk_div;
reg transfer_in_progress; // Added control signal for pipelining

// 优化后的进位和计数器信号
reg [2:0] bit_cnt_next;
reg [2:0] byte_counter_next;

// Define states
parameter IDLE = 3'b000;
parameter START = 3'b001;
parameter TRANSFER = 3'b010;
parameter STOP = 3'b011;
parameter WAIT = 3'b100; // Added wait state for pipelining

// Tri-state control using continuous assignment
assign scl = (state != IDLE) ? clk_div : 1'bz;
assign sda = (sda_oen) ? 1'bz : sda_out;

// Initial register values
initial begin
    byte_counter = 0;
    bit_cnt = 0;
    state = IDLE;
    next_state = IDLE;
    transfer_done = 0;
    rx_payload = 0;
    transfer_in_progress = 0;
    next_shift_reg = 0;
    for (byte_counter = 0; byte_counter < 4; byte_counter = byte_counter + 1)
        shift_reg[byte_counter] = 0;
    byte_counter = 0;
    bit_cnt_next = 0;
    byte_counter_next = 0;
end

// State calculation - separated from data path for better timing
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n) begin
        next_state <= IDLE;
        transfer_in_progress <= 0;
    end else begin
        case(state)
            IDLE: begin
                if (start_transfer) begin
                    next_state <= START;
                    transfer_in_progress <= 1;
                end else begin
                    next_state <= IDLE;
                    transfer_in_progress <= 0;
                end
            end
            START: begin
                next_state <= TRANSFER;
                transfer_in_progress <= 1;
            end
            TRANSFER: begin
                // 优化比较链 - 使用范围比较和逻辑操作替代多级比较
                if ((bit_cnt == 3'd7) && (byte_counter >= BYTE_COUNT-1)) begin
                    next_state <= STOP;
                end else begin
                    next_state <= TRANSFER;
                end
                transfer_in_progress <= 1;
            end
            STOP: begin
                next_state <= WAIT;
                transfer_in_progress <= 0;
            end
            WAIT: begin
                next_state <= IDLE;
                transfer_in_progress <= 0;
            end
            default: begin
                next_state <= IDLE;
                transfer_in_progress <= 0;
            end
        endcase
    end
end

// 优化计数器逻辑 - 使用直接加法替代带状进位加法器
always @(*) begin
    // 默认值赋值
    bit_cnt_next = 3'd0;
    byte_counter_next = byte_counter;
    
    if (state == TRANSFER) begin
        // 位计数器简化增加逻辑
        bit_cnt_next = bit_cnt + 3'd1;
        
        // 字节计数器优化逻辑
        if (bit_cnt == 3'd7) begin
            if (byte_counter < BYTE_COUNT-1) begin
                byte_counter_next = byte_counter + 3'd1;
            end
        end
    end else if (state == IDLE && start_transfer) begin
        // 重置字节计数器
        byte_counter_next = 3'd0;
    end
end

// Main state update and control logic - pipelined from state calculation
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n) begin
        state <= IDLE;
        byte_counter <= 0;
        bit_cnt <= 0;
        transfer_done <= 0;
    end else begin
        state <= next_state;
        
        // Transfer done signal generation - moved outside critical path
        if (state == STOP) begin
            transfer_done <= 1;
        end else if (state == IDLE) begin
            transfer_done <= 0;
        end
        
        // 使用优化后的计数器更新逻辑
        bit_cnt <= bit_cnt_next;
        byte_counter <= byte_counter_next;
    end
end

// Payload loading logic - 优化多字节处理
always @(posedge clk) begin
    if (state == IDLE && start_transfer) begin
        // 优化载荷加载逻辑，减少条件判断
        shift_reg[0] <= tx_payload[7:0];
        if (DATA_WIDTH > 8) begin
            next_shift_reg <= tx_payload[15:8];
        end
    end else if (state == TRANSFER) begin
        if (bit_cnt == 3'd6 && byte_counter < BYTE_COUNT-1) begin
            // 优化字节选择逻辑
            case (byte_counter)
                3'd0: next_shift_reg <= tx_payload[15:8];
                3'd1: next_shift_reg <= tx_payload[23:16];
                3'd2: next_shift_reg <= tx_payload[31:24];
                default: next_shift_reg <= 8'h0;
            endcase
        end else if (bit_cnt == 3'd7 && byte_counter < BYTE_COUNT-1) begin
            shift_reg[byte_counter+1] <= next_shift_reg;
        end
    end
end

// Rx payload capture logic - 优化多字节合并逻辑
always @(posedge clk) begin
    if (state == STOP) begin
        // 优化收到数据的处理方式
        case (BYTE_COUNT)
            1: rx_payload <= shift_reg[0];
            2: rx_payload <= {shift_reg[1], shift_reg[0]};
            3: rx_payload <= {shift_reg[2], shift_reg[1], shift_reg[0]};
            default: rx_payload <= {shift_reg[3], shift_reg[2], shift_reg[1], shift_reg[0]};
        endcase
    end
end

// Clock divider - separated for better timing
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n) begin
        clk_div <= 1'b1;
    end else if (transfer_in_progress) begin
        clk_div <= ~clk_div;
    end else begin
        clk_div <= 1'b1;
    end
end
endmodule