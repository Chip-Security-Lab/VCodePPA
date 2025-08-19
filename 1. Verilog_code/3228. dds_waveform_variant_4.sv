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
    
    // 2位减法器查找表
    reg [1:0] sub_lut [0:15]; // 4种可能的被减数 x 4种可能的减数 = 16种组合
    
    initial begin
        sin_lut[0] = 8'd128; sin_lut[1] = 8'd176; sin_lut[2] = 8'd218; sin_lut[3] = 8'd245;
        sin_lut[4] = 8'd255; sin_lut[5] = 8'd245; sin_lut[6] = 8'd218; sin_lut[7] = 8'd176;
        sin_lut[8] = 8'd128; sin_lut[9] = 8'd79;  sin_lut[10] = 8'd37; sin_lut[11] = 8'd10;
        sin_lut[12] = 8'd0;  sin_lut[13] = 8'd10; sin_lut[14] = 8'd37; sin_lut[15] = 8'd79;
        
        // 初始化2位减法器查找表
        // 查找表索引 = {被减数, 减数}
        sub_lut[4'b0000] = 2'b00; // 0 - 0 = 0
        sub_lut[4'b0001] = 2'b11; // 0 - 1 = -1 (3 in 2-bit)
        sub_lut[4'b0010] = 2'b10; // 0 - 2 = -2 (2 in 2-bit)
        sub_lut[4'b0011] = 2'b01; // 0 - 3 = -3 (1 in 2-bit)
        sub_lut[4'b0100] = 2'b01; // 1 - 0 = 1
        sub_lut[4'b0101] = 2'b00; // 1 - 1 = 0
        sub_lut[4'b0110] = 2'b11; // 1 - 2 = -1 (3 in 2-bit)
        sub_lut[4'b0111] = 2'b10; // 1 - 3 = -2 (2 in 2-bit)
        sub_lut[4'b1000] = 2'b10; // 2 - 0 = 2
        sub_lut[4'b1001] = 2'b01; // 2 - 1 = 1
        sub_lut[4'b1010] = 2'b00; // 2 - 2 = 0
        sub_lut[4'b1011] = 2'b11; // 2 - 3 = -1 (3 in 2-bit)
        sub_lut[4'b1100] = 2'b11; // 3 - 0 = 3
        sub_lut[4'b1101] = 2'b10; // 3 - 1 = 2
        sub_lut[4'b1110] = 2'b01; // 3 - 2 = 1
        sub_lut[4'b1111] = 2'b00; // 3 - 3 = 0
    end
    
    reg [OUT_WIDTH-1:0] triangle_out;
    reg [1:0] subtractor_in_a, subtractor_in_b;
    reg [1:0] subtractor_result;
    reg [OUT_WIDTH-3:0] remaining_bits;
    
    always @(posedge clk) begin
        if (reset)
            phase_acc <= {PHASE_WIDTH{1'b0}};
        else
            phase_acc <= phase_acc + freq_word;
            
        // 三角波形处理 - 使用查找表辅助减法器
        subtractor_in_a = {2{1'b0}}; // 默认为0
        subtractor_in_b = phase_acc[PHASE_WIDTH-2:PHASE_WIDTH-3]; // 取前2位用于减法
        
        // 使用查找表执行减法操作
        subtractor_result = sub_lut[{subtractor_in_a, subtractor_in_b}];
        
        // 保留剩余位
        remaining_bits = phase_acc[PHASE_WIDTH-4:PHASE_WIDTH-OUT_WIDTH-1];
        
        // 根据相位最高位决定是否需要取反
        if (phase_acc[PHASE_WIDTH-1]) begin
            triangle_out = {subtractor_result, remaining_bits};
        end else begin
            triangle_out = {phase_acc[PHASE_WIDTH-2:PHASE_WIDTH-3], remaining_bits};
        end
            
        // 将case语句转换为if-else级联结构
        if (wave_sel == 2'b00) begin
            // Sine波形
            dds_out <= sin_lut[phase_acc[PHASE_WIDTH-1:PHASE_WIDTH-4]];
        end else if (wave_sel == 2'b01) begin
            // 三角波
            dds_out <= triangle_out;
        end else if (wave_sel == 2'b10) begin
            // 锯齿波
            dds_out <= phase_acc[PHASE_WIDTH-1:PHASE_WIDTH-OUT_WIDTH];
        end else begin
            // 方波 (wave_sel == 2'b11)
            dds_out <= phase_acc[PHASE_WIDTH-1] ? {OUT_WIDTH{1'b1}} : {OUT_WIDTH{1'b0}};
        end
    end
endmodule