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
reg [2:0] bit_cnt;
reg sda_oen;
reg sda_out;
reg [2:0] state;
reg clk_div;
wire scl_out_reg;
wire sda_out_reg;

// 寄存器化的输入信号
reg start_transfer_reg;
reg [DATA_WIDTH-1:0] tx_payload_reg;

// Define states
localparam IDLE = 3'b000;
localparam START = 3'b001;
localparam TRANSFER = 3'b010;
localparam STOP = 3'b011;

// 寄存器化输入信号，将输入端寄存器向前移动
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n) begin
        start_transfer_reg <= 1'b0;
        tx_payload_reg <= {DATA_WIDTH{1'b0}};
    end else begin
        start_transfer_reg <= start_transfer;
        tx_payload_reg <= tx_payload;
    end
end

// 将组合逻辑转换为寄存器输出，减少关键路径
assign scl_out_reg = (state == IDLE) ? 1'b1 : clk_div;
assign sda_out_reg = sda_out;

// Tri-state buffers with simplified logic paths
assign scl = (state == IDLE) ? 1'bz : scl_out_reg;
assign sda = sda_oen ? 1'bz : sda_out_reg;

// Initial register values
initial begin
    byte_counter = 0;
    bit_cnt = 0;
    state = IDLE;
    transfer_done = 0;
    rx_payload = 0;
    sda_oen = 1'b1;
    sda_out = 1'b1;
    clk_div = 1'b1;
    for (byte_counter = 0; byte_counter < 4; byte_counter = byte_counter + 1)
        shift_reg[byte_counter] = 0;
    byte_counter = 0;
end

// Split state machine logic from data path to balance critical paths
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n) begin
        state <= IDLE;
        transfer_done <= 0;
    end else begin
        case(state)
            IDLE: begin
                if (start_transfer_reg) begin  // 使用寄存器化的输入信号
                    state <= START;
                    transfer_done <= 1'b0;
                end
            end
            // Additional states would be implemented here
            default: state <= IDLE;
        endcase
    end
end

// Separate counter handling from state machine for better timing
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n) begin
        byte_counter <= 0;
        bit_cnt <= 0;
    end else if (state == IDLE && start_transfer_reg) begin  // 使用寄存器化的输入信号
        byte_counter <= 0;
        bit_cnt <= 0;
    end else if (state == TRANSFER && bit_cnt == 3'd7) begin
        if (DATA_WIDTH > 8 && byte_counter < BYTE_COUNT-1) begin
            byte_counter <= byte_counter + 1;
        end
        bit_cnt <= 0;
    end else if (state == TRANSFER) begin
        bit_cnt <= bit_cnt + 1;
    end
end

// 重定时后的数据加载逻辑，使用寄存器化的输入信号
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n) begin
        // Reset shift registers
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;
        shift_reg[2] <= 0;
        shift_reg[3] <= 0;
    end else if (state == IDLE && start_transfer_reg) begin  // 使用寄存器化的输入信号
        // Load first byte on transfer start
        shift_reg[0] <= (DATA_WIDTH <= 8) ? tx_payload_reg : tx_payload_reg[7:0];
        
        // Preload additional bytes based on data width
        if (DATA_WIDTH > 8) shift_reg[1] <= tx_payload_reg[15:8];
        if (DATA_WIDTH > 16) shift_reg[2] <= tx_payload_reg[23:16];
        if (DATA_WIDTH > 24) shift_reg[3] <= tx_payload_reg[31:24];
    end 
end

// 将时钟分频器也进行寄存器化，改善时序
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n) begin
        clk_div <= 1'b1;
    end else begin
        clk_div <= ~clk_div;
    end
end

// Simplified byte handling logic
always @(posedge clk) begin
    if (state == TRANSFER && bit_cnt == 3'd7 && DATA_WIDTH > 8 && byte_counter < BYTE_COUNT-1) begin
        // This logic is now simplified since we preload values
        // Just leaving this for future implementation
    end
end

endmodule