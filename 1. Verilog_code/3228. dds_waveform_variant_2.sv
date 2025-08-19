//SystemVerilog
module dds_waveform #(
    parameter PHASE_WIDTH = 12,
    parameter OUT_WIDTH = 8
)(
    input clk,
    input reset,
    input [PHASE_WIDTH-1:0] freq_word,
    input [1:0] wave_sel,
    output reg [OUT_WIDTH-1:0] dds_out
);
    // 相位累加器
    reg [PHASE_WIDTH-1:0] phase_acc;
    
    // 正弦查找表ROM - 将ROM改为wire以实现更好的资源共享
    wire [OUT_WIDTH-1:0] sin_val;
    // 将LUT优化为组合逻辑，避免使用初始化块
    function [OUT_WIDTH-1:0] sin_lookup;
        input [3:0] addr;
        begin
            case(addr)
                4'd0:  sin_lookup = 8'd128;
                4'd1:  sin_lookup = 8'd176;
                4'd2:  sin_lookup = 8'd218;
                4'd3:  sin_lookup = 8'd245;
                4'd4:  sin_lookup = 8'd255;
                4'd5:  sin_lookup = 8'd245;
                4'd6:  sin_lookup = 8'd218;
                4'd7:  sin_lookup = 8'd176;
                4'd8:  sin_lookup = 8'd128;
                4'd9:  sin_lookup = 8'd79;
                4'd10: sin_lookup = 8'd37;
                4'd11: sin_lookup = 8'd10;
                4'd12: sin_lookup = 8'd0;
                4'd13: sin_lookup = 8'd10;
                4'd14: sin_lookup = 8'd37;
                4'd15: sin_lookup = 8'd79;
            endcase
        end
    endfunction
    
    // 预计算各种波形值，将组合逻辑分离出来以改善时序
    wire [OUT_WIDTH-1:0] triangle_val;
    wire [OUT_WIDTH-1:0] sawtooth_val;
    wire [OUT_WIDTH-1:0] square_val;
    wire [3:0] lut_addr;
    
    // 从相位累加器中提取地址
    assign lut_addr = phase_acc[PHASE_WIDTH-1:PHASE_WIDTH-4];
    assign sin_val = sin_lookup(lut_addr);
    
    // 使用二进制补码减法算法实现减法器
    wire [OUT_WIDTH-1:0] phase_segment;
    wire [OUT_WIDTH-1:0] complement_value;
    wire [OUT_WIDTH-1:0] adder_result;
    wire adder_carry;
    
    // 提取相位段
    assign phase_segment = phase_acc[PHASE_WIDTH-2:PHASE_WIDTH-OUT_WIDTH-1];
    
    // 根据相位最高位判断是否需要取反
    assign complement_value = phase_acc[PHASE_WIDTH-1] ? ~phase_segment : phase_segment;
    
    // 使用补码加法实现三角波
    assign {adder_carry, adder_result} = phase_acc[PHASE_WIDTH-1] ? 
                                         {1'b0, ~phase_segment} + {1'b0, 1'b1} : 
                                         {1'b0, phase_segment};
    
    // 三角波使用补码减法结果
    assign triangle_val = adder_result;
    
    // 锯齿波和方波逻辑简化
    assign sawtooth_val = phase_acc[PHASE_WIDTH-1:PHASE_WIDTH-OUT_WIDTH];
    assign square_val = {OUT_WIDTH{phase_acc[PHASE_WIDTH-1]}};
    
    // 相位累加器更新逻辑 - 使用补码加法
    always @(posedge clk) begin
        if (reset)
            phase_acc <= {PHASE_WIDTH{1'b0}};
        else begin
            // 使用补码加法实现相位累加
            phase_acc <= phase_acc + freq_word;
        end
    end
    
    // 波形选择逻辑 - 将case语句独立出来并优化
    always @(posedge clk) begin
        if (reset)
            dds_out <= {OUT_WIDTH{1'b0}};
        else
            case (wave_sel)
                2'b00: dds_out <= sin_val;       // 正弦波
                2'b01: dds_out <= triangle_val;  // 三角波
                2'b10: dds_out <= sawtooth_val;  // 锯齿波
                2'b11: dds_out <= square_val;    // 方波
            endcase
    end
endmodule