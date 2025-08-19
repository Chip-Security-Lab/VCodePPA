//SystemVerilog
module shift_register_ctrl(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [1:0] shift_mode, // 00:none, 01:left, 10:right, 11:rotate
    input wire serial_in,
    input wire parallel_load,
    input wire [7:0] parallel_data,
    output wire [7:0] data_out,
    output wire serial_out
);
    parameter [1:0] IDLE = 2'b00, LOAD = 2'b01, 
                    SHIFT = 2'b10, OUTPUT = 2'b11;
    
    // 内部信号声明
    wire [1:0] next_state;
    wire [7:0] next_shift_register;
    wire next_serial_out;
    wire [7:0] next_data_out;
    
    reg [1:0] state;
    reg [7:0] shift_register;
    reg serial_out_reg;
    reg [7:0] data_out_reg;
    
    // 组合逻辑部分 - 状态转换
    next_state_logic state_logic(
        .state(state),
        .parallel_load(parallel_load),
        .enable(enable),
        .shift_mode(shift_mode),
        .next_state(next_state)
    );
    
    // 组合逻辑部分 - 数据处理
    datapath_logic datapath(
        .state(state),
        .shift_mode(shift_mode),
        .serial_in(serial_in),
        .parallel_data(parallel_data),
        .shift_register(shift_register),
        .next_shift_register(next_shift_register),
        .next_serial_out(next_serial_out),
        .next_data_out(next_data_out)
    );
    
    // 时序逻辑部分
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            shift_register <= 8'd0;
            data_out_reg <= 8'd0;
            serial_out_reg <= 1'b0;
        end else begin
            state <= next_state;
            shift_register <= next_shift_register;
            data_out_reg <= next_data_out;
            serial_out_reg <= next_serial_out;
        end
    end
    
    // 输出赋值
    assign data_out = data_out_reg;
    assign serial_out = serial_out_reg;
endmodule

// 状态转换组合逻辑模块
module next_state_logic(
    input wire [1:0] state,
    input wire parallel_load,
    input wire enable,
    input wire [1:0] shift_mode,
    output reg [1:0] next_state
);
    parameter [1:0] IDLE = 2'b00, LOAD = 2'b01, 
                    SHIFT = 2'b10, OUTPUT = 2'b11;
    
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

// 数据处理组合逻辑模块
module datapath_logic(
    input wire [1:0] state,
    input wire [1:0] shift_mode,
    input wire serial_in,
    input wire [7:0] parallel_data,
    input wire [7:0] shift_register,
    output reg [7:0] next_shift_register,
    output reg next_serial_out,
    output reg [7:0] next_data_out
);
    parameter [1:0] IDLE = 2'b00, LOAD = 2'b01, 
                    SHIFT = 2'b10, OUTPUT = 2'b11;
    
    always @(*) begin
        // 默认值 - 保持当前状态
        next_shift_register = shift_register;
        next_serial_out = 1'b0;
        next_data_out = next_data_out;
        
        case (state)
            IDLE: begin
                // 保持当前值
            end
            LOAD: begin
                next_shift_register = parallel_data;
            end
            SHIFT: begin
                case (shift_mode)
                    2'b01: begin // 左移
                        next_shift_register = {shift_register[6:0], serial_in};
                        next_serial_out = shift_register[7];
                    end
                    2'b10: begin // 右移
                        next_shift_register = {serial_in, shift_register[7:1]};
                        next_serial_out = shift_register[0];
                    end
                    2'b11: begin // 旋转
                        next_shift_register = {shift_register[6:0], shift_register[7]};
                        next_serial_out = shift_register[7];
                    end
                    default: begin
                        // 保持当前值
                    end
                endcase
            end
            OUTPUT: begin
                next_data_out = shift_register;
            end
        endcase
    end
endmodule