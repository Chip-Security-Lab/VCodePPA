//SystemVerilog
module crc_error_injection (
    input clk,
    input rst_n,
    input valid,            // 数据有效信号
    input inject_err,
    input [7:0] data_in,
    output reg ready,       // 接收就绪信号
    output reg [15:0] crc,
    output reg data_processed
);
    wire [7:0] real_data = inject_err ? ~data_in : data_in;
    
    // 状态机定义
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam COMPLETE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [15:0] temp_crc;
    
    // 实现CRC16计算函数
    function [15:0] crc16;
        input [7:0] data;
        input [15:0] crc_in;
        reg [15:0] crc_out;
        integer i;
        begin
            crc_out = crc_in;
            for (i = 0; i < 8; i = i + 1) begin
                if ((data[i] ^ crc_out[15]) == 1'b1)
                    crc_out = {crc_out[14:0], 1'b0} ^ 16'h8005;
                else
                    crc_out = {crc_out[14:0], 1'b0};
            end
            crc16 = crc_out;
        end
    endfunction
    
    // 状态转换逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 状态机下一状态逻辑
    always @(*) begin
        case (state)
            IDLE: begin
                if (valid && ready)
                    next_state = PROCESS;
                else
                    next_state = IDLE;
            end
            PROCESS: begin
                next_state = COMPLETE;
            end
            COMPLETE: begin
                if (!valid)
                    next_state = IDLE;
                else
                    next_state = COMPLETE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // CRC计算及输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc <= 16'h0000;
            ready <= 1'b1;
            data_processed <= 1'b0;
            temp_crc <= 16'h0000;
        end else begin
            case (state)
                IDLE: begin
                    data_processed <= 1'b0;
                    if (valid && ready) begin
                        temp_crc <= crc16(real_data, crc);
                        ready <= 1'b0;
                    end
                end
                PROCESS: begin
                    crc <= temp_crc;
                    data_processed <= 1'b1;
                end
                COMPLETE: begin
                    if (!valid) begin
                        ready <= 1'b1;
                        data_processed <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule