//SystemVerilog
module shift_register_ctrl(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [1:0] shift_mode, // 00:none, 01:left, 10:right, 11:rotate
    input wire serial_in,
    input wire parallel_load,
    input wire [7:0] parallel_data,
    input wire [7:0] multiplier_a,    // 乘法输入 A
    input wire [7:0] multiplier_b,    // 乘法输入 B
    output reg [7:0] data_out,
    output reg serial_out,
    output reg [15:0] mult_result     // 乘法结果输出
);
    wire [15:0] mult_result_internal;
    reg [7:0] shift_register_stage1, shift_register_stage2;
    reg [15:0] mult_result_stage1;

    // 状态定义
    parameter [1:0] IDLE = 2'b00, LOAD = 2'b01, 
                    SHIFT = 2'b10, OUTPUT = 2'b11;
    reg [1:0] state, next_state;

    // 实例化乘法子模块
    karatsuba_multiplier mult_inst (
        .a(multiplier_a),
        .b(multiplier_b),
        .result(mult_result_internal)
    );

    // 实例化移位寄存器子模块
    shift_register_unit shift_reg_inst (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .shift_mode(shift_mode),
        .serial_in(serial_in),
        .parallel_load(parallel_load),
        .parallel_data(parallel_data),
        .shift_register(shift_register_stage1),
        .data_out(data_out),
        .serial_out(serial_out)
    );

    // 流水线寄存器控制
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            mult_result <= 16'd0;
        end else begin
            state <= next_state;
            // 更新乘法结果
            mult_result_stage1 <= mult_result_internal;
            mult_result <= mult_result_stage1;
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                if (parallel_load)
                    next_state = LOAD;
                else if (enable && shift_mode != 2'b00)
                    next_state = SHIFT;
                else
                    next_state = IDLE;
            end
            LOAD: begin
                next_state = OUTPUT;
            end
            SHIFT: begin
                next_state = OUTPUT;
            end
            OUTPUT: begin
                if (parallel_load)
                    next_state = LOAD;
                else if (enable && shift_mode != 2'b00)
                    next_state = SHIFT;
                else
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule

// 子模块：Karatsuba乘法器
module karatsuba_multiplier(
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] result
);
    reg [3:0] a_high, a_low, b_high, b_low;
    reg [7:0] p1, p2, p3;
    reg [7:0] temp;

    always @(*) begin
        if (a[7:4] == 0 || b[7:4] == 0) begin
            result = a * b;
        end else begin
            // 拆分数字
            a_high = a[7:4];
            a_low = a[3:0];
            b_high = b[7:4];
            b_low = b[3:0];

            // Karatsuba的三个子乘法
            p1 = a_high * b_high;          // 高位相乘
            p2 = a_low * b_low;            // 低位相乘
            temp = (a_high + a_low) * (b_high + b_low); 
            p3 = temp - p1 - p2;           // 中间项
            
            // 合并结果
            result = {p1, 8'b0} + {p3, 4'b0} + p2;
        end
    end
endmodule

// 子模块：移位寄存器单元
module shift_register_unit(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [1:0] shift_mode, // 00:none, 01:left, 10:right, 11:rotate
    input wire serial_in,
    input wire parallel_load,
    input wire [7:0] parallel_data,
    output reg [7:0] shift_register,
    output reg [7:0] data_out,
    output reg serial_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            shift_register <= 8'd0;
            data_out <= 8'd0;
            serial_out <= 1'b0;
        end else if (parallel_load) begin
            shift_register <= parallel_data;
        end else if (enable) begin
            case (shift_mode)
                2'b01: begin // Shift left
                    shift_register <= {shift_register[6:0], serial_in};
                    serial_out <= shift_register[7];
                end
                2'b10: begin // Shift right
                    shift_register <= {serial_in, shift_register[7:1]};
                    serial_out <= shift_register[0];
                end
                2'b11: begin // Rotate
                    shift_register <= {shift_register[6:0], shift_register[7]};
                    serial_out <= shift_register[7];
                end
            endcase
        end
        data_out <= shift_register;
    end
endmodule