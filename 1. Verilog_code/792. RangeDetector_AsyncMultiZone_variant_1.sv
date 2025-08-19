//SystemVerilog
// SystemVerilog
module RangeDetector_AsyncMultiZone #(
    parameter ZONES = 4,
    parameter WIDTH = 8
)(
    input wire clk,                        // 时钟信号
    input wire rst_n,                      // 复位信号
    input wire [WIDTH-1:0] data_in,        // 输入数据
    input wire [WIDTH-1:0] bounds [ZONES*2-1:0], // 区间边界数组
    output reg [ZONES-1:0] zone_flags      // 区间标志输出
);

    // 分段处理比较逻辑 - 第一级流水线信号
    reg [WIDTH-1:0] data_in_reg;
    reg [WIDTH-1:0] bounds_reg [ZONES*2-1:0];
    
    // 第二级流水线 - 比较结果信号
    reg [ZONES-1:0] lower_bound_check;
    reg [ZONES-1:0] upper_bound_check;
    
    // 第一级流水线 - 寄存输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= {WIDTH{1'b0}};
            for (int j = 0; j < ZONES*2; j++) begin
                bounds_reg[j] <= {WIDTH{1'b0}};
            end
        end else begin
            data_in_reg <= data_in;
            for (int j = 0; j < ZONES*2; j++) begin
                bounds_reg[j] <= bounds[j];
            end
        end
    end
    
    // 第二级流水线 - 计算比较结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lower_bound_check <= {ZONES{1'b0}};
            upper_bound_check <= {ZONES{1'b0}};
        end else begin
            for (int i = 0; i < ZONES; i++) begin
                // 拆分比较逻辑，减少关键路径长度
                lower_bound_check[i] <= (data_in_reg >= bounds_reg[2*i]);
                upper_bound_check[i] <= (data_in_reg <= bounds_reg[2*i+1]);
            end
        end
    end
    
    // 第三级流水线 - 生成最终区间标志
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            zone_flags <= {ZONES{1'b0}};
        end else begin
            for (int i = 0; i < ZONES; i++) begin
                // 使用与运算符合并比较结果
                zone_flags[i] <= lower_bound_check[i] & upper_bound_check[i];
            end
        end
    end

endmodule