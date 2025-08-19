//SystemVerilog
module int_ctrl_double_buf #(parameter WIDTH=8) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             valid_in,
    input  wire             swap,
    input  wire [WIDTH-1:0] new_status,
    output wire [WIDTH-1:0] current_status,
    output wire             valid_out
);

    // 流水线寄存器定义
    reg [WIDTH-1:0] buf1_stage1, buf1_stage2;  // buf1的两级流水线寄存器
    reg [WIDTH-1:0] buf2_stage1, buf2_stage2;  // buf2的两级流水线寄存器
    reg             valid_stage1, valid_stage2; // 流水线有效信号
    reg             swap_stage1;                // 流水线内的swap控制信号
    reg [WIDTH-1:0] new_status_stage1;          // 输入数据流水线寄存器

    // 输入捕获 - 流水线第一级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1     <= 1'b0;
            swap_stage1      <= 1'b0;
            new_status_stage1 <= {WIDTH{1'b0}};
            buf1_stage1      <= {WIDTH{1'b0}};
            buf2_stage1      <= {WIDTH{1'b0}};
        end else begin
            valid_stage1     <= valid_in;
            swap_stage1      <= swap;
            new_status_stage1 <= new_status;
            buf1_stage1      <= buf1_stage2;
            buf2_stage1      <= buf2_stage2;
        end
    end

    // 计算和更新 - 流水线第二级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2  <= 1'b0;
            buf1_stage2   <= {WIDTH{1'b0}};
            buf2_stage2   <= {WIDTH{1'b0}};
        end else begin
            valid_stage2  <= valid_stage1;
            
            // 根据流水线第一级的信号进行更新
            if (valid_stage1) begin
                if (swap_stage1) begin
                    // 交换buf1和buf2
                    buf1_stage2 <= buf2_stage1;
                end else begin
                    buf1_stage2 <= buf1_stage1;
                end
                
                // 更新buf2为新值
                buf2_stage2 <= new_status_stage1;
            end
        end
    end

    // 输出赋值 - 从第二级流水线寄存器输出
    assign current_status = buf1_stage2;
    assign valid_out = valid_stage2;

endmodule