//SystemVerilog
module shift_register_ctrl(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [1:0] shift_mode,  // 00:none, 01:left, 10:right, 11:rotate
    input wire serial_in,
    input wire parallel_load,
    input wire [7:0] parallel_data,
    output reg [7:0] data_out,
    output reg serial_out
);
    // 优化参数定义，使用独热码编码降低状态转换逻辑复杂度
    parameter [3:0] IDLE   = 4'b0001, 
                    LOAD   = 4'b0010, 
                    SHIFT  = 4'b0100, 
                    OUTPUT = 4'b1000;
                    
    reg [3:0] state, next_state;
    reg [7:0] shift_register;
    
    // 提前计算状态转换条件，减少逻辑深度
    wire load_condition = parallel_load;
    wire shift_condition = enable && (|shift_mode);
    
    // 分离串行输出逻辑，减少关键路径
    reg serial_out_next;
    
    // 状态转移和数据处理逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            shift_register <= 8'd0;
            data_out <= 8'd0;
            serial_out <= 1'b0;
        end else begin
            state <= next_state;
            serial_out <= serial_out_next;
            
            case (state)
                LOAD: begin
                    shift_register <= parallel_data;
                end
                SHIFT: begin
                    case (shift_mode)
                        2'b01: shift_register <= {shift_register[6:0], serial_in};
                        2'b10: shift_register <= {serial_in, shift_register[7:1]};
                        2'b11: shift_register <= {shift_register[6:0], shift_register[7]};
                        default: shift_register <= shift_register;
                    endcase
                end
                OUTPUT: begin
                    data_out <= shift_register;
                end
                default: begin
                    // IDLE: 保持当前值
                end
            endcase
        end
    end
    
    // 分离串行输出计算逻辑，减少关键路径
    always @(*) begin
        case (state)
            SHIFT: begin
                case (shift_mode)
                    2'b01: serial_out_next = shift_register[7]; // 左移
                    2'b10: serial_out_next = shift_register[0]; // 右移
                    2'b11: serial_out_next = shift_register[7]; // 循环
                    default: serial_out_next = serial_out;
                endcase
            end
            default: serial_out_next = serial_out;
        endcase
    end
    
    // 优化状态转换逻辑，将条件判断扁平化
    always @(*) begin
        next_state = IDLE; // 默认值
        
        case (state)
            IDLE: begin
                if (load_condition)
                    next_state = LOAD;
                else if (shift_condition)
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
                if (load_condition)
                    next_state = LOAD;
                else if (shift_condition)
                    next_state = SHIFT;
                else
                    next_state = IDLE;
            end
        endcase
    end
endmodule