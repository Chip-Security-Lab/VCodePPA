//SystemVerilog
module serial_to_parallel_recovery #(
    parameter WIDTH = 8
)(
    input wire bit_clk,
    input wire reset,
    input wire serial_in,
    input wire frame_sync,
    output reg [WIDTH-1:0] parallel_out,
    output reg data_valid
);
    // 主移位寄存器
    reg [WIDTH-1:0] shift_reg;
    // 比特计数器
    reg [3:0] bit_count;
    // 流水线寄存器，用于切割组合逻辑路径
    reg [WIDTH-2:0] shift_reg_stage1;
    reg serial_in_stage1;
    // 流水线寄存器，用于计数逻辑
    reg [3:0] bit_count_next;
    reg bit_count_equal_width_minus_1;
    
    // 合并的时序逻辑块
    always @(posedge bit_clk or posedge reset) begin
        if (reset) begin
            // 重置所有寄存器
            shift_reg <= {WIDTH{1'b0}};
            bit_count <= 4'h0;
            shift_reg_stage1 <= {(WIDTH-1){1'b0}};
            serial_in_stage1 <= 1'b0;
            bit_count_next <= 4'h0;
            bit_count_equal_width_minus_1 <= 1'b0;
            parallel_out <= {WIDTH{1'b0}};
            data_valid <= 1'b0;
        end else if (frame_sync) begin
            // 帧同步时重置所有寄存器
            shift_reg <= {WIDTH{1'b0}};
            bit_count <= 4'h0;
            shift_reg_stage1 <= {(WIDTH-1){1'b0}};
            serial_in_stage1 <= 1'b0;
            bit_count_next <= 4'h0;
            bit_count_equal_width_minus_1 <= 1'b0;
            parallel_out <= {WIDTH{1'b0}};
            data_valid <= 1'b0;
        end else begin
            // 第一级流水线 - 移位操作
            shift_reg <= {shift_reg[WIDTH-2:0], serial_in};
            
            // 中间状态保存
            shift_reg_stage1 <= shift_reg[WIDTH-2:0];
            serial_in_stage1 <= serial_in;
            
            // 计数逻辑
            bit_count_next <= bit_count + 4'h1;
            bit_count_equal_width_minus_1 <= (bit_count == WIDTH-1);
            
            // 计数器更新
            if (bit_count == WIDTH-1) begin
                bit_count <= 4'h0;
            end else begin
                bit_count <= bit_count + 4'h1;
            end
            
            // 第二级流水线 - 输出控制
            if (bit_count_equal_width_minus_1) begin
                parallel_out <= {shift_reg_stage1, serial_in_stage1};
                data_valid <= 1'b1;
            end else begin
                data_valid <= 1'b0;
            end
        end
    end
endmodule