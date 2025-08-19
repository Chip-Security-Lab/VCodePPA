//SystemVerilog
module universal_shifter (
    input wire clk, rst,
    input wire req,                // 请求信号 (替代valid)
    input wire [1:0] mode,         // 00:hold, 01:shift right, 10:shift left, 11:load
    input wire [3:0] parallel_in,
    input wire left_in, right_in,
    output wire [3:0] q,
    output wire ack                // 应答信号 (替代ready)
);
    // Internal signals
    wire [3:0] hold_out;
    wire [3:0] shift_right_out;
    wire [3:0] shift_left_out;
    wire [3:0] mux_out;
    wire [3:0] reg_q;
    reg req_r;                     // 寄存req信号
    
    // 应答信号生成逻辑
    assign ack = req;              // 简单的请求-应答握手
    
    // 在请求有效时才处理数据
    always @(posedge clk or posedge rst) begin
        if (rst)
            req_r <= 1'b0;
        else
            req_r <= req;
    end
    
    // Register module instantiation
    register_unit register (
        .clk(clk),
        .rst(rst),
        .d(mux_out),
        .q(reg_q),
        .req(req),
        .ack(ack)
    );
    
    // Hold operation module
    hold_unit hold_op (
        .q_in(reg_q),
        .q_out(hold_out)
    );
    
    // Shift right operation module
    shift_right_unit shift_right_op (
        .q_in(reg_q),
        .right_in(right_in),
        .q_out(shift_right_out)
    );
    
    // Shift left operation module
    shift_left_unit shift_left_op (
        .q_in(reg_q),
        .left_in(left_in),
        .q_out(shift_left_out)
    );
    
    // Operation selector module
    operation_selector op_select (
        .mode(mode),
        .hold_data(hold_out),
        .shift_right_data(shift_right_out),
        .shift_left_data(shift_left_out),
        .parallel_in(parallel_in),
        .mux_out(mux_out),
        .req(req)
    );
    
    // Connect register output to module output
    assign q = reg_q;
    
endmodule

// Register module for storing the current state
module register_unit (
    input wire clk,
    input wire rst,
    input wire [3:0] d,
    input wire req,         // 请求信号
    input wire ack,         // 应答信号
    output reg [3:0] q
);
    always @(posedge clk) begin
        if (rst)
            q <= 4'b0000;
        else if (req && ack) // 只在请求和应答都有效时更新
            q <= d;
    end
endmodule

// Hold operation module
module hold_unit (
    input wire [3:0] q_in,
    output wire [3:0] q_out
);
    assign q_out = q_in; // Simply pass through the current value
endmodule

// Shift right operation module
module shift_right_unit (
    input wire [3:0] q_in,
    input wire right_in,
    output wire [3:0] q_out
);
    assign q_out = {right_in, q_in[3:1]}; // Shift right operation
endmodule

// Shift left operation module
module shift_left_unit (
    input wire [3:0] q_in,
    input wire left_in,
    output wire [3:0] q_out
);
    assign q_out = {q_in[2:0], left_in}; // Shift left operation
endmodule

// Operation selector module
module operation_selector (
    input wire [1:0] mode,
    input wire [3:0] hold_data,
    input wire [3:0] shift_right_data,
    input wire [3:0] shift_left_data,
    input wire [3:0] parallel_in,
    input wire req,         // 请求信号
    output reg [3:0] mux_out
);
    always @(*) begin
        if (req) begin      // 只在请求有效时选择操作
            case (mode)
                2'b00: mux_out = hold_data;         // Hold
                2'b01: mux_out = shift_right_data;  // Shift right
                2'b10: mux_out = shift_left_data;   // Shift left
                2'b11: mux_out = parallel_in;       // Parallel load
                default: mux_out = hold_data;
            endcase
        end else begin
            mux_out = hold_data;  // 默认保持当前值
        end
    end
endmodule