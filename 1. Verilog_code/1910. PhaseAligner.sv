module PhaseAligner #(parameter PHASE_STEPS=8) (
    input clk_ref, clk_data,
    output reg [7:0] aligned_data
);
    reg [7:0] sample_buffer [0:PHASE_STEPS-1];
    reg clk_ref_sample;  // 添加采样寄存器
    integer i;

    always @(posedge clk_data) begin
        clk_ref_sample <= clk_ref;  // 采样clk_ref
        
        // 修复错误的数组赋值
        for (i = PHASE_STEPS-1; i > 0; i = i - 1) begin
            sample_buffer[i] <= sample_buffer[i-1];
        end
        sample_buffer[0] <= clk_ref_sample;
    end

    // 相位检测
    wire [7:0] phase_detect;
    assign phase_detect = sample_buffer[0] ^ sample_buffer[PHASE_STEPS-1];
    
    always @(posedge clk_data) begin
        if (|phase_detect) begin  // 修复比较逻辑
            aligned_data <= sample_buffer[PHASE_STEPS/2];
        end
    end
endmodule