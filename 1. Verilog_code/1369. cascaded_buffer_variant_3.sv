//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module cascaded_buffer (
    input wire clk,
    input wire rst_n,         // 添加复位信号
    input wire [7:0] data_in,
    input wire valid_in,      // 输入数据有效信号
    output wire ready_in,     // 输入接口准备好接收数据
    input wire cascade_en,    // 级联使能
    output reg [7:0] data_out,
    output reg valid_out,     // 输出数据有效信号
    input wire ready_out      // 下游模块准备好接收数据
);

    // 流水线寄存器
    reg [7:0] stage1_data;
    reg stage1_valid;
    reg [7:0] stage2_data;
    reg stage2_valid;
    
    // 流水线控制信号
    wire stage1_ready;
    wire stage2_ready;
    
    // 流水线数据流控制
    assign stage2_ready = ready_out || !stage2_valid;
    assign stage1_ready = stage2_ready || !stage1_valid;
    assign ready_in = stage1_ready;
    
    // 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 8'h0;
            stage1_valid <= 1'b0;
        end else if (stage1_ready) begin
            if (valid_in && cascade_en) begin
                stage1_data <= data_in;
                stage1_valid <= 1'b1;
            end else if (!valid_in) begin
                stage1_valid <= 1'b0;
            end
        end
    end
    
    // 第二级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= 8'h0;
            stage2_valid <= 1'b0;
        end else if (stage2_ready) begin
            if (stage1_valid && cascade_en) begin
                stage2_data <= stage1_data;
                stage2_valid <= stage1_valid;
            end else if (!stage1_valid) begin
                stage2_valid <= 1'b0;
            end
        end
    end
    
    // 输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'h0;
            valid_out <= 1'b0;
        end else if (ready_out) begin
            if (stage2_valid && cascade_en) begin
                data_out <= stage2_data;
                valid_out <= stage2_valid;
            end else if (!stage2_valid) begin
                valid_out <= 1'b0;
            end
        end
    end
    
endmodule