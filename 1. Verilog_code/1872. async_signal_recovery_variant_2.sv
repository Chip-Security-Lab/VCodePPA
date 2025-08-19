//SystemVerilog
module async_signal_recovery (
    input wire clk,
    input wire rst_n,
    input wire [7:0] noisy_input,
    input wire signal_present,
    input wire valid_in,
    output reg ready_in,
    output reg [7:0] recovered_signal,
    output reg valid_out,
    input wire ready_out
);

    // 内部流水线寄存器
    reg [7:0] filtered_signal_stage1;
    reg signal_present_stage1;
    reg [7:0] filtered_signal_stage2;
    reg valid_stage1, valid_stage2;
    
    // 第一级流水线逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            filtered_signal_stage1 <= 8'b0;
            signal_present_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            if (valid_in && ready_in) begin
                filtered_signal_stage1 <= noisy_input;
                signal_present_stage1 <= signal_present;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 第二级流水线逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            filtered_signal_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1 && ready_out) begin
                filtered_signal_stage2 <= signal_present_stage1 ? filtered_signal_stage1 : 8'b0;
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 第三级流水线逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recovered_signal <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            if (valid_stage2 && ready_out) begin
                recovered_signal <= (filtered_signal_stage2 > 8'd128) ? 8'hFF : 8'h00;
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end
    
    // Ready信号生成逻辑
    always @(*) begin
        ready_in = !valid_stage1 || (valid_stage1 && ready_out);
    end
    
endmodule