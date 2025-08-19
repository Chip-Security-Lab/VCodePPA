//SystemVerilog
module rz_codec (
    input wire clk, rst_n,
    input wire data_in,       // For encoding
    input wire rz_in,         // For decoding
    output reg rz_out,        // Encoded output
    output reg data_out,      // Decoded output
    output reg valid_out      // Valid decoded bit
);
    // RZ encoding: '1' is encoded as high-low, '0' is encoded as low-low
    reg [1:0] bit_phase;
    reg [1:0] sample_count;
    reg data_sampled;
    
    // 流水线寄存器
    reg data_in_pipe;
    reg rz_in_pipe;
    reg bit_phase_0_pipe, bit_phase_1_pipe;
    reg sample_count_valid_pipe;
    reg data_sampled_pipe;
    
    // Optimized bit phase counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            bit_phase <= 2'b00;
        else 
            bit_phase <= bit_phase + 1'b1;
    end
    
    // 流水线寄存器更新 - 第一级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_pipe <= 1'b0;
            rz_in_pipe <= 1'b0;
            bit_phase_0_pipe <= 1'b0;
            bit_phase_1_pipe <= 1'b0;
        end
        else begin
            data_in_pipe <= data_in;
            rz_in_pipe <= rz_in;
            bit_phase_0_pipe <= bit_phase[0];
            bit_phase_1_pipe <= bit_phase[1];
        end
    end
    
    // Optimized RZ encoder - 使用流水线寄存器减少组合逻辑延迟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rz_out <= 1'b0;
        end
        else begin
            // First half cycle (bit_phase_1_pipe == 0)
            if (!bit_phase_1_pipe) begin
                rz_out <= data_in_pipe & ~bit_phase_0_pipe; // High only during first quarter for '1'
            end
            // Second half cycle (bit_phase_1_pipe == 1)
            else begin
                rz_out <= 1'b0; // Always low for second half
            end
        end
    end
    
    // 中间状态流水线处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_count_valid_pipe <= 1'b0;
            data_sampled_pipe <= 1'b0;
        end
        else begin
            // 预先计算解码器的状态条件，切割组合逻辑路径
            sample_count_valid_pipe <= (bit_phase == 2'b10) && (sample_count == 2'b01);
            data_sampled_pipe <= data_sampled;
        end
    end
    
    // RZ decoder implementation - 优化关键路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;
            valid_out <= 1'b0;
            sample_count <= 2'b00;
            data_sampled <= 1'b0;
        end
        else begin
            // Default valid signal
            valid_out <= 1'b0;
            
            // Sample incoming RZ signal at optimal points
            if (bit_phase == 2'b00) begin
                data_sampled <= rz_in_pipe;  // Sample at start of bit
                sample_count <= 2'b01;
            end
            else if (sample_count_valid_pipe) begin
                // High at start and low at middle indicates '1'
                data_out <= data_sampled_pipe & ~rz_in_pipe;
                valid_out <= 1'b1;
                sample_count <= 2'b00;
            end
        end
    end
endmodule