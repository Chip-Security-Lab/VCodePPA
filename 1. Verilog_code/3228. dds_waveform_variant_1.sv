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
    reg [PHASE_WIDTH-1:0] phase_acc;
    reg [OUT_WIDTH-1:0] sin_lut [0:15]; // 16-entry sine LUT
    
    // 预解码波形选择信号，减少关键路径延迟
    reg [3:0] wave_sel_decoded;
    reg [OUT_WIDTH-1:0] sine_out, triangle_out, sawtooth_out, square_out;
    
    initial begin
        sin_lut[0] = 8'd128; sin_lut[1] = 8'd176; sin_lut[2] = 8'd218; sin_lut[3] = 8'd245;
        sin_lut[4] = 8'd255; sin_lut[5] = 8'd245; sin_lut[6] = 8'd218; sin_lut[7] = 8'd176;
        sin_lut[8] = 8'd128; sin_lut[9] = 8'd79;  sin_lut[10] = 8'd37; sin_lut[11] = 8'd10;
        sin_lut[12] = 8'd0;  sin_lut[13] = 8'd10; sin_lut[14] = 8'd37; sin_lut[15] = 8'd79;
    end
    
    // 相位累加器逻辑
    always @(posedge clk) begin
        if (reset)
            phase_acc <= {PHASE_WIDTH{1'b0}};
        else
            phase_acc <= phase_acc + freq_word;
    end
    
    // 波形生成逻辑 - 并行计算所有波形
    always @(posedge clk) begin
        if (reset) begin
            sine_out <= {OUT_WIDTH{1'b0}};
            triangle_out <= {OUT_WIDTH{1'b0}};
            sawtooth_out <= {OUT_WIDTH{1'b0}};
            square_out <= {OUT_WIDTH{1'b0}};
            wave_sel_decoded <= 4'b0001; // 默认选择正弦波
        end else begin
            // 波形计算并行化
            sine_out <= sin_lut[phase_acc[PHASE_WIDTH-1:PHASE_WIDTH-4]];
            triangle_out <= phase_acc[PHASE_WIDTH-1] ? ~phase_acc[PHASE_WIDTH-2:PHASE_WIDTH-OUT_WIDTH-1] : 
                                                     phase_acc[PHASE_WIDTH-2:PHASE_WIDTH-OUT_WIDTH-1];
            sawtooth_out <= phase_acc[PHASE_WIDTH-1:PHASE_WIDTH-OUT_WIDTH];
            square_out <= {OUT_WIDTH{phase_acc[PHASE_WIDTH-1]}};
            
            // 解码选择信号 - 独热码形式
            case (wave_sel)
                2'b00: wave_sel_decoded <= 4'b0001; // Sine
                2'b01: wave_sel_decoded <= 4'b0010; // Triangle
                2'b10: wave_sel_decoded <= 4'b0100; // Sawtooth
                2'b11: wave_sel_decoded <= 4'b1000; // Square
            endcase
        end
    end
    
    // 使用多路复用器选择器进行优化的输出选择
    always @(posedge clk) begin
        if (reset)
            dds_out <= {OUT_WIDTH{1'b0}};
        else begin
            case (1'b1) // 优化的独热码多路复用
                wave_sel_decoded[0]: dds_out <= sine_out;
                wave_sel_decoded[1]: dds_out <= triangle_out;
                wave_sel_decoded[2]: dds_out <= sawtooth_out;
                wave_sel_decoded[3]: dds_out <= square_out;
                default: dds_out <= sine_out; // 默认为正弦波
            endcase
        end
    end
endmodule