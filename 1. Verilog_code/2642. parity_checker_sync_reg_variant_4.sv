//SystemVerilog
module parity_checker_req_ack (
    input clk, rst_n,
    input [15:0] data,
    input req,     // 请求信号，替代原来的valid
    output reg ack, // 应答信号，替代原来的ready
    output reg parity
);

reg data_valid;
reg [15:0] data_reg;
wire calc_parity = ~^data_reg; // 偶校验

// 状态定义
localparam IDLE = 2'b00;
localparam PROCESSING = 2'b01;
localparam DONE = 2'b10;
reg [1:0] state, next_state;

// 状态转换逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        state <= IDLE;
    else 
        state <= next_state;
end

// 状态机逻辑
always @(*) begin
    next_state = state;
    case (state)
        IDLE: if (req) next_state = PROCESSING;
        PROCESSING: next_state = DONE;
        DONE: if (!req) next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

// 数据寄存和处理逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_valid <= 1'b0;
        data_reg <= 16'b0;
        parity <= 1'b0;
        ack <= 1'b0;
    end else begin
        case (state)
            IDLE: begin
                ack <= 1'b0;
                if (req) begin
                    data_reg <= data;
                    data_valid <= 1'b1;
                end
            end
            PROCESSING: begin
                parity <= calc_parity;
                ack <= 1'b1;
                data_valid <= 1'b0;
            end
            DONE: begin
                if (!req) begin
                    ack <= 1'b0;
                end
            end
        endcase
    end
end

endmodule