//SystemVerilog
// 顶层模块
module wave11_piecewise #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    output wire [WIDTH-1:0] wave_out
);
    // 内部连接信号
    wire [4:0] state;
    wire state_reset;
    
    // 状态控制器实例化
    state_controller #(
        .MAX_STATE(5'b11110)
    ) u_state_controller (
        .clk        (clk),
        .rst        (rst),
        .state      (state),
        .state_reset(state_reset)
    );
    
    // 波形生成器实例化
    waveform_generator #(
        .WIDTH(WIDTH)
    ) u_waveform_generator (
        .clk        (clk),
        .rst        (rst),
        .state      (state),
        .wave_out   (wave_out)
    );
    
endmodule

// 状态控制器子模块
module state_controller #(
    parameter MAX_STATE = 5'b11110
)(
    input  wire       clk,
    input  wire       rst,
    output reg  [4:0] state,
    output wire       state_reset
);
    // 状态定义 - 独冷编码
    localparam STATE0 = 5'b11110;
    localparam STATE1 = 5'b11101;
    localparam STATE2 = 5'b11011;
    localparam STATE3 = 5'b10111;
    localparam STATE4 = 5'b01111;
    
    // 状态重置信号
    assign state_reset = (state == MAX_STATE);
    
    // 状态计数控制
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state <= STATE0;
        end else begin
            case(state)
                STATE0: state <= STATE1;
                STATE1: state <= STATE2;
                STATE2: state <= STATE3;
                STATE3: state <= STATE4;
                STATE4: state <= STATE0;
                default: state <= STATE0;
            endcase
        end
    end
endmodule

// 波形生成器子模块
module waveform_generator #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [4:0]       state,
    output reg  [WIDTH-1:0] wave_out
);
    // 状态定义 - 独冷编码
    localparam STATE0 = 5'b11110;
    localparam STATE1 = 5'b11101;
    localparam STATE2 = 5'b11011;
    localparam STATE3 = 5'b10111;
    localparam STATE4 = 5'b01111;
    
    // 波形生成查找表
    function [WIDTH-1:0] get_wave_value;
        input [4:0] state_in;
        begin
            case(state_in)
                STATE0 : get_wave_value = 8'd10;
                STATE1 : get_wave_value = 8'd50;
                STATE2 : get_wave_value = 8'd100;
                STATE3 : get_wave_value = 8'd150;
                STATE4 : get_wave_value = 8'd200;
                default: get_wave_value = 8'd0;
            endcase
        end
    endfunction
    
    // 波形生成逻辑
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            wave_out <= {WIDTH{1'b0}};
        end else begin
            wave_out <= get_wave_value(state);
        end
    end
endmodule