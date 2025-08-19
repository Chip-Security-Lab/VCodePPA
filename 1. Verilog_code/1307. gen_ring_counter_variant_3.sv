//SystemVerilog
//IEEE 1364-2005 Verilog

module gen_ring_counter #(parameter WIDTH=8) (
    input clk,          // 时钟输入
    input rst,          // 复位信号
    input valid_in,     // 输入有效信号
    output valid_out,   // 输出有效信号
    output [WIDTH-1:0] cnt // 计数器输出
);
    // 输入寄存器
    reg valid_in_reg;
    reg [WIDTH-1:0] cnt_feedback;
    
    // 内部信号声明
    reg [WIDTH-1:0] cnt_stage1;
    reg [WIDTH-1:0] cnt_stage2;
    reg [WIDTH-1:0] cnt_stage3;
    
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    // 输入寄存化 - 将寄存器前移到输入处
    always @(posedge clk) begin
        if (rst) begin
            valid_in_reg <= 1'b0;
            cnt_feedback <= {{WIDTH-1{1'b0}}, 1'b1};
        end
        else begin
            valid_in_reg <= valid_in;
            cnt_feedback <= cnt_stage3;
        end
    end
    
    // 阶段1: 使用预先寄存的输入
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end
        else begin
            if (valid_in_reg) begin
                cnt_stage1 <= {cnt_feedback[0], cnt_feedback[WIDTH-1:1]};
                valid_stage1 <= 1'b1;
            end
            else if (valid_stage1) begin
                cnt_stage1 <= {cnt_stage1[0], cnt_stage1[WIDTH-1:1]};
            end
            else begin
                valid_stage1 <= valid_in_reg;
            end
        end
    end
    
    // 阶段2: 中间处理阶段
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else begin
            cnt_stage2 <= cnt_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 阶段3: 最终处理阶段
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end
        else begin
            cnt_stage3 <= cnt_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出赋值
    assign cnt = cnt_stage3;
    assign valid_out = valid_stage3;
    
endmodule