//SystemVerilog
// 顶层模块
module MIPI_PacketGenerator #(
    parameter PACKET_TYPE = 8'h18,
    parameter PAYLOAD_SIZE = 4
)(
    input wire clk,
    input wire rst,
    input wire trigger,
    output wire [7:0] packet_data,
    output wire packet_valid
);

    // 状态定义
    localparam IDLE = 3'b001;
    localparam HEADER = 3'b010; 
    localparam PAYLOAD = 3'b100;
    localparam CRC = 3'b000;

    // 内部信号
    wire [2:0] current_state;
    wire [3:0] payload_counter;
    wire [7:0] crc;
    wire [7:0] next_packet_data;
    wire next_packet_valid;
    wire [2:0] next_state;
    wire [3:0] next_payload_counter;
    wire [7:0] next_crc;

    // 状态机控制模块
    MIPI_StateController state_ctrl (
        .clk(clk),
        .rst(rst),
        .current_state(current_state),
        .next_state(next_state),
        .payload_counter(payload_counter),
        .next_payload_counter(next_payload_counter),
        .crc(crc),
        .next_crc(next_crc)
    );

    // 数据生成模块
    MIPI_DataGenerator #(
        .PACKET_TYPE(PACKET_TYPE),
        .PAYLOAD_SIZE(PAYLOAD_SIZE)
    ) data_gen (
        .current_state(current_state),
        .payload_counter(payload_counter),
        .crc(crc),
        .trigger(trigger),
        .next_packet_data(next_packet_data),
        .next_packet_valid(next_packet_valid)
    );

    // 输出寄存器模块
    MIPI_OutputReg output_reg (
        .clk(clk),
        .rst(rst),
        .next_packet_data(next_packet_data),
        .next_packet_valid(next_packet_valid),
        .packet_data(packet_data),
        .packet_valid(packet_valid)
    );

endmodule

// 状态机控制模块
module MIPI_StateController (
    input wire clk,
    input wire rst,
    input wire [2:0] next_state,
    input wire [3:0] next_payload_counter,
    input wire [7:0] next_crc,
    output reg [2:0] current_state,
    output reg [3:0] payload_counter,
    output reg [7:0] crc
);

    always @(posedge clk) begin
        if (rst) begin
            current_state <= 3'b001; // IDLE
            payload_counter <= 4'd0;
            crc <= 8'h00;
        end else begin
            current_state <= next_state;
            payload_counter <= next_payload_counter;
            crc <= next_crc;
        end
    end

endmodule

// 数据生成模块
module MIPI_DataGenerator #(
    parameter PACKET_TYPE = 8'h18,
    parameter PAYLOAD_SIZE = 4
)(
    input wire [2:0] current_state,
    input wire [3:0] payload_counter,
    input wire [7:0] crc,
    input wire trigger,
    output reg [7:0] next_packet_data,
    output reg next_packet_valid
);

    localparam IDLE = 3'b001;
    localparam HEADER = 3'b010;
    localparam PAYLOAD = 3'b100;
    localparam CRC = 3'b000;

    always @(*) begin
        next_packet_data = 8'h00;
        next_packet_valid = 1'b0;
        
        case(current_state)
            IDLE: begin
                if (trigger) begin
                    next_packet_data = PACKET_TYPE;
                    next_packet_valid = 1'b1;
                end
            end
            
            HEADER: begin
                next_packet_data = PAYLOAD_SIZE;
                next_packet_valid = 1'b1;
            end
            
            PAYLOAD: begin
                if (payload_counter < PAYLOAD_SIZE) begin
                    next_packet_data = 8'hA5 + payload_counter;
                    next_packet_valid = 1'b1;
                end
            end
            
            CRC: begin
                next_packet_data = crc;
                next_packet_valid = 1'b0;
            end
            
            default: begin
                next_packet_data = 8'h00;
                next_packet_valid = 1'b0;
            end
        endcase
    end

endmodule

// 输出寄存器模块
module MIPI_OutputReg (
    input wire clk,
    input wire rst,
    input wire [7:0] next_packet_data,
    input wire next_packet_valid,
    output reg [7:0] packet_data,
    output reg packet_valid
);

    always @(posedge clk) begin
        if (rst) begin
            packet_data <= 8'h00;
            packet_valid <= 1'b0;
        end else begin
            packet_data <= next_packet_data;
            packet_valid <= next_packet_valid;
        end
    end

endmodule