//SystemVerilog
// IEEE 1364-2005 Verilog standard
module barrel_shifter_top (
    input wire [7:0] data_in,
    input wire [2:0] shift_amount,
    input wire direction, // 0: right, 1: left
    output wire [7:0] data_out
);
    // 左移和右移的输出
    wire [7:0] left_shifted, right_shifted;
    
    // 实例化分解后的子模块
    shift_controller shift_ctrl (
        .data_in(data_in),
        .shift_amount(shift_amount),
        .direction(direction),
        .left_shifted(left_shifted),
        .right_shifted(right_shifted),
        .data_out(data_out)
    );
    
    // 实例化左移模块
    karatsuba_shifter #(
        .DIRECTION(1) // 1表示左移
    ) left_shifter (
        .data_in(data_in),
        .shift_amount(shift_amount),
        .data_out(left_shifted)
    );
    
    // 实例化右移模块
    karatsuba_shifter #(
        .DIRECTION(0) // 0表示右移
    ) right_shifter (
        .data_in(data_in),
        .shift_amount(shift_amount),
        .data_out(right_shifted)
    );
endmodule

// 移位控制器模块，负责选择最终输出
module shift_controller (
    input wire [7:0] data_in,
    input wire [2:0] shift_amount,
    input wire direction,
    input wire [7:0] left_shifted,
    input wire [7:0] right_shifted,
    output reg [7:0] data_out
);
    // 基于direction选择最终输出，使用if-else替代条件运算符
    always @(*) begin
        if (direction) begin
            data_out = left_shifted;
        end else begin
            data_out = right_shifted;
        end
    end
endmodule

// 参数化Karatsuba移位器模块，可配置为左移或右移
module karatsuba_shifter #(
    parameter DIRECTION = 1 // 1: 左移, 0: 右移
)(
    input wire [7:0] data_in,
    input wire [2:0] shift_amount,
    output reg [7:0] data_out
);
    // 临时变量
    reg [3:0] high, low;
    reg [3:0] shifted_high, shifted_low;
    
    always @(*) begin
        // 将输入数据分为高4位和低4位
        high = data_in[7:4];
        low = data_in[3:0];
        
        // 初始化输出
        data_out = 8'b0;
        
        if (DIRECTION) begin
            // 左移逻辑
            case(shift_amount)
                3'd0: data_out = data_in;
                3'd1: begin
                    shifted_high = {high[2:0], low[3]};
                    shifted_low = {low[2:0], 1'b0};
                    data_out = {shifted_high, shifted_low};
                end
                3'd2: begin
                    shifted_high = {high[1:0], low[3:2]};
                    shifted_low = {low[1:0], 2'b0};
                    data_out = {shifted_high, shifted_low};
                end
                3'd3: begin
                    shifted_high = {high[0], low[3:1]};
                    shifted_low = {low[0], 3'b0};
                    data_out = {shifted_high, shifted_low};
                end
                3'd4: begin
                    shifted_high = low;
                    shifted_low = 4'b0;
                    data_out = {shifted_high, shifted_low};
                end
                3'd5: begin
                    shifted_high = {low[2:0], 1'b0};
                    shifted_low = 4'b0;
                    data_out = {shifted_high, shifted_low};
                end
                3'd6: begin
                    shifted_high = {low[1:0], 2'b0};
                    shifted_low = 4'b0;
                    data_out = {shifted_high, shifted_low};
                end
                3'd7: begin
                    shifted_high = {low[0], 3'b0};
                    shifted_low = 4'b0;
                    data_out = {shifted_high, shifted_low};
                end
            endcase
        end else begin
            // 右移逻辑
            case(shift_amount)
                3'd0: data_out = data_in;
                3'd1: begin
                    shifted_high = {1'b0, high[3:1]};
                    shifted_low = {high[0], low[3:1]};
                    data_out = {shifted_high, shifted_low};
                end
                3'd2: begin
                    shifted_high = {2'b0, high[3:2]};
                    shifted_low = {high[1:0], low[3:2]};
                    data_out = {shifted_high, shifted_low};
                end
                3'd3: begin
                    shifted_high = {3'b0, high[3]};
                    shifted_low = {high[2:0], low[3]};
                    data_out = {shifted_high, shifted_low};
                end
                3'd4: begin
                    shifted_high = 4'b0;
                    shifted_low = high;
                    data_out = {shifted_high, shifted_low};
                end
                3'd5: begin
                    shifted_high = 4'b0;
                    shifted_low = {1'b0, high[3:1]};
                    data_out = {shifted_high, shifted_low};
                end
                3'd6: begin
                    shifted_high = 4'b0;
                    shifted_low = {2'b0, high[3:2]};
                    data_out = {shifted_high, shifted_low};
                end
                3'd7: begin
                    shifted_high = 4'b0;
                    shifted_low = {3'b0, high[3]};
                    data_out = {shifted_high, shifted_low};
                end
            endcase
        end
    end
endmodule