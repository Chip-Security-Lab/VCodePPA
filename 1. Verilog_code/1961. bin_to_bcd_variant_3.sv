//SystemVerilog
// 功能: 二进制转BCD模块，采用分层always块结构

module bin_to_bcd #(
    parameter BIN_WIDTH = 8,
    parameter DIGITS = 3  // 输出BCD位数
)(
    input  [BIN_WIDTH-1:0] binary_in,
    output reg [DIGITS*4-1:0] bcd_out
);

    // 中间寄存器用于转换过程
    reg [BIN_WIDTH+DIGITS*4-1:0] shift_reg;
    reg [BIN_WIDTH-1:0] binary_latched;
    reg [$clog2(BIN_WIDTH+1)-1:0] bit_counter;
    reg [1:0] state;

    // 状态定义
    localparam IDLE      = 2'd0;
    localparam LOAD      = 2'd1;
    localparam SHIFT     = 2'd2;
    localparam OUTPUT    = 2'd3;

    // 控制信号
    reg shift_enable;
    reg load_enable;
    reg output_enable;

    // 功能说明: 控制主状态机
    always @(*) begin
        shift_enable   = 1'b0;
        load_enable    = 1'b0;
        output_enable  = 1'b0;
        case (state)
            IDLE:    load_enable   = 1'b1;
            LOAD:    shift_enable  = 1'b1;
            SHIFT:   if (bit_counter == BIN_WIDTH)
                         output_enable = 1'b1;
                     else
                         shift_enable = 1'b1;
            OUTPUT:  load_enable   = 1'b1;
            default: ;
        endcase
    end

    // 功能说明: 主状态机状态转移
    always @(*) begin
        case (state)
            IDLE:    state = LOAD;
            LOAD:    state = SHIFT;
            SHIFT:   if (bit_counter == BIN_WIDTH)
                         state = OUTPUT;
                     else
                         state = SHIFT;
            OUTPUT:  state = IDLE;
            default: state = IDLE;
        endcase
    end

    // 功能说明: 输入锁存与初始移位寄存器加载
    always @(*) begin
        if (load_enable) begin
            binary_latched = binary_in;
            shift_reg = { {(DIGITS*4){1'b0}}, binary_in };
            bit_counter = 0;
        end
    end

    // 功能说明: BCD加3校正过程
    integer digit_idx;
    always @(*) begin
        if (shift_enable) begin
            for (digit_idx = 0; digit_idx < DIGITS; digit_idx = digit_idx + 1) begin
                if (shift_reg[BIN_WIDTH + digit_idx*4 +: 4] > 4)
                    shift_reg[BIN_WIDTH + digit_idx*4 +: 4] = shift_reg[BIN_WIDTH + digit_idx*4 +: 4] + 4'd3;
            end
            shift_reg = shift_reg << 1;
            bit_counter = bit_counter + 1;
        end
    end

    // 功能说明: 输出BCD结果
    always @(*) begin
        if (output_enable) begin
            bcd_out = shift_reg[BIN_WIDTH+DIGITS*4-1:BIN_WIDTH];
        end
    end

endmodule