//SystemVerilog
module gen_ring_counter #(parameter WIDTH=8) (
    input  wire            clk,
    input  wire            rst,
    input  wire            enable,
    output reg [WIDTH-1:0] cnt,
    output reg             valid_out
);

    // 优化的流水线阶段寄存器
    reg [WIDTH-1:0] stage1_data;
    reg [WIDTH-1:0] stage2_data;
    reg             stage1_valid;
    reg             stage2_valid;
    
    // 预计算下一状态以减少关键路径延迟
    wire [WIDTH-1:0] next_cnt = {cnt[0], cnt[WIDTH-1:1]};
    
    // 第一级流水线：加载/计算下一状态
    always @(posedge clk) begin
        if (rst) begin
            stage1_data  <= {{WIDTH-1{1'b0}}, 1'b1};
            stage1_valid <= 1'b0;
        end
        else if (enable) begin
            stage1_data  <= next_cnt;
            stage1_valid <= 1'b1;
        end
    end

    // 第二级流水线：准备输出
    always @(posedge clk) begin
        if (rst) begin
            stage2_data  <= {{WIDTH-1{1'b0}}, 1'b1};
            stage2_valid <= 1'b0;
        end
        else if (enable) begin
            stage2_data  <= stage1_data;
            stage2_valid <= stage1_valid;
        end
    end

    // 输出寄存器
    always @(posedge clk) begin
        if (rst) begin
            cnt       <= {{WIDTH-1{1'b0}}, 1'b1};
            valid_out <= 1'b0;
        end
        else if (enable) begin
            cnt       <= stage2_data;
            valid_out <= stage2_valid;
        end
    end

endmodule