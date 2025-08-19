//SystemVerilog
module phase_accum_generator(
    input clock,
    input reset_n,
    input [11:0] phase_increment,
    input [1:0] waveform_select,
    output reg [7:0] wave_out
);
    reg [11:0] phase_accumulator;
    reg [7:0] wave_out_next;
    
    // 相位累加器逻辑
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            phase_accumulator <= 12'd0;
        else
            phase_accumulator <= phase_accumulator + phase_increment;
    end
    
    // 波形生成逻辑 - 使用组合逻辑生成下一个值
    always @(*) begin
        case (waveform_select)
            2'b00: begin // 锯齿波
                wave_out_next = phase_accumulator[11:4];
            end
            2'b01: begin // 三角波
                if (phase_accumulator[11]) begin
                    wave_out_next = ~phase_accumulator[10:3];
                end else begin
                    wave_out_next = phase_accumulator[10:3];
                end
            end
            2'b10: begin // 方波
                if (phase_accumulator[11]) begin
                    wave_out_next = 8'd255;
                end else begin
                    wave_out_next = 8'd0;
                end
            end
            2'b11: begin // 脉冲波
                if (phase_accumulator[11:8] < 4'd4) begin
                    wave_out_next = 8'd255;
                end else begin
                    wave_out_next = 8'd0;
                end
            end
            default: begin
                wave_out_next = 8'd0;
            end
        endcase
    end
    
    // 寄存波形输出，减少毛刺
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            wave_out <= 8'd0;
        else
            wave_out <= wave_out_next;
    end
endmodule