//SystemVerilog
module shift_parity_checker (
    input wire clk,
    input wire rst_n,         // 复位信号
    input wire serial_in,     // 串行输入数据
    input wire req_in,        // 请求输入信号
    output wire ack_in,       // 应答输入信号
    output wire parity,       // 奇偶校验结果
    output wire req_out,      // 请求输出信号
    input wire ack_out        // 应答输出信号
);
    wire [7:0] shift_data;
    wire req_internal;
    wire ack_internal;
    
    // 实例化移位寄存器子模块
    shift_register shift_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .serial_in(serial_in),
        .req_in(req_in),
        .ack_in(ack_in),
        .shift_data(shift_data),
        .req_out(req_internal),
        .ack_out(ack_internal)
    );
    
    // 实例化奇偶校验计算子模块
    parity_calculator parity_calc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(shift_data),
        .req_in(req_internal),
        .ack_in(ack_internal),
        .parity_out(parity),
        .req_out(req_out),
        .ack_out(ack_out)
    );
    
endmodule

module shift_register (
    input wire clk,
    input wire rst_n,
    input wire serial_in,
    input wire req_in,
    output reg ack_in,
    output reg [7:0] shift_data,
    output reg req_out,
    input wire ack_out
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam RECEIVING = 2'b01;
    localparam SENDING = 2'b10;
    localparam WAITING = 2'b11;
    
    reg [1:0] state, next_state;
    reg [2:0] bit_count;
    
    // 状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 状态转换逻辑
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: 
                if (req_in)
                    next_state = RECEIVING;
            RECEIVING: 
                if (bit_count == 3'b111)
                    next_state = SENDING;
            SENDING: 
                if (ack_out)
                    next_state = WAITING;
            WAITING: 
                if (!req_in)
                    next_state = IDLE;
            default: 
                next_state = IDLE;
        endcase
    end
    
    // 输出和计数逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_data <= 8'b0;
            bit_count <= 3'b0;
            ack_in <= 1'b0;
            req_out <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    bit_count <= 3'b0;
                    ack_in <= 1'b0;
                    req_out <= 1'b0;
                end
                RECEIVING: begin
                    ack_in <= 1'b1;
                    shift_data <= {shift_data[6:0], serial_in};
                    bit_count <= bit_count + 1'b1;
                    req_out <= 1'b0;
                end
                SENDING: begin
                    req_out <= 1'b1;
                    ack_in <= 1'b1;
                end
                WAITING: begin
                    req_out <= 1'b0;
                    ack_in <= 1'b0;
                end
            endcase
        end
    end
endmodule

module parity_calculator (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire req_in,
    output reg ack_in,
    output reg parity_out,
    output reg req_out,
    input wire ack_out
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam COMPUTING = 2'b01;
    localparam SENDING = 2'b10;
    localparam WAITING = 2'b11;
    
    reg [1:0] state, next_state;
    
    // 状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 状态转换逻辑
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: 
                if (req_in)
                    next_state = COMPUTING;
            COMPUTING: 
                next_state = SENDING;
            SENDING: 
                if (ack_out)
                    next_state = WAITING;
            WAITING: 
                if (!req_in)
                    next_state = IDLE;
            default: 
                next_state = IDLE;
        endcase
    end
    
    // 输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_out <= 1'b0;
            ack_in <= 1'b0;
            req_out <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    ack_in <= 1'b0;
                    req_out <= 1'b0;
                end
                COMPUTING: begin
                    parity_out <= ^data_in;
                    ack_in <= 1'b1;
                end
                SENDING: begin
                    req_out <= 1'b1;
                end
                WAITING: begin
                    req_out <= 1'b0;
                    ack_in <= 1'b0;
                end
            endcase
        end
    end
endmodule