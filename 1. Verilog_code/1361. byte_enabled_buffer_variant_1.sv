//SystemVerilog
module byte_enabled_buffer (
    input wire clk,
    input wire rst_n,
    input wire [31:0] data_in,
    input wire [3:0] byte_en,
    input wire write,
    input wire valid_in,
    output wire ready_in,
    output wire valid_out,
    input wire ready_out,
    output reg [31:0] data_out
);
    // 流水线阶段1寄存器
    reg [31:0] data_stage1;
    reg [3:0] byte_en_stage1;
    reg write_stage1;
    reg valid_stage1;
    
    // 流水线阶段2寄存器
    reg [31:0] data_stage2;
    reg valid_stage2;
    
    // 优化的流水线控制逻辑
    wire stage2_ready = !valid_stage2 || ready_out;
    wire stage1_ready = !valid_stage1 || stage2_ready;
    
    assign ready_in = stage1_ready;
    assign valid_out = valid_stage2;
    
    // 字节使能处理逻辑
    reg [31:0] merged_data;
    
    always @(*) begin
        merged_data = data_stage2;
        
        if (byte_en_stage1[0])
            merged_data[7:0] = data_stage1[7:0];
        if (byte_en_stage1[1])
            merged_data[15:8] = data_stage1[15:8];
        if (byte_en_stage1[2])
            merged_data[23:16] = data_stage1[23:16];
        if (byte_en_stage1[3])
            merged_data[31:24] = data_stage1[31:24];
    end
    
    // 第一级流水线 - 寄存数据和控制信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 32'b0;
            byte_en_stage1 <= 4'b0;
            write_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else if (stage1_ready) begin
            data_stage1 <= data_in;
            byte_en_stage1 <= byte_en;
            write_stage1 <= write;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 32'b0;
            valid_stage2 <= 1'b0;
        end else if (stage2_ready) begin
            valid_stage2 <= valid_stage1;
            
            if (valid_stage1 && write_stage1) begin
                data_stage2 <= merged_data;
            end
        end
    end
    
    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 32'b0;
        end else if (valid_stage2 && ready_out) begin
            data_out <= data_stage2;
        end
    end
    
endmodule