//SystemVerilog
// CRC16计算子模块
module crc16_calculator(
    input clk,
    input reset,
    input [7:0] data_in,
    input calc_en,
    output reg [15:0] crc_out
);
    localparam POLY = 16'h1021;
    
    always @(posedge clk) begin
        if (reset) begin
            crc_out <= 16'hFFFF;
        end else if (calc_en) begin
            crc_out <= {crc_out[14:0], 1'b0} ^ (crc_out[15] ? POLY : 16'h0000) ^ {8'h00, data_in};
        end
    end
endmodule

// 状态控制子模块
module crc16_controller(
    input clk,
    input reset,
    input data_req,
    input crc_ack,
    output reg data_ack,
    output reg crc_req,
    output reg calc_en
);
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam WAIT_ACK = 2'b10;
    
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            data_ack <= 1'b0;
            crc_req <= 1'b0;
            calc_en <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (data_req) begin
                        data_ack <= 1'b1;
                        calc_en <= 1'b1;
                        state <= PROCESS;
                    end
                end
                
                PROCESS: begin
                    data_ack <= 1'b0;
                    crc_req <= 1'b1;
                    calc_en <= 1'b0;
                    state <= WAIT_ACK;
                end
                
                WAIT_ACK: begin
                    if (crc_ack) begin
                        crc_req <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule

// 顶层模块
module crc16_with_req_ack(
    input clk,
    input reset,
    input [7:0] data_in,
    input data_req,
    output data_ack,
    output [15:0] crc,
    output crc_req,
    input crc_ack
);
    wire calc_en;
    
    crc16_calculator crc_calc(
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .calc_en(calc_en),
        .crc_out(crc)
    );
    
    crc16_controller ctrl(
        .clk(clk),
        .reset(reset),
        .data_req(data_req),
        .crc_ack(crc_ack),
        .data_ack(data_ack),
        .crc_req(crc_req),
        .calc_en(calc_en)
    );
endmodule