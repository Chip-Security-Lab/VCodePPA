//SystemVerilog
module TwosComplement (
    input  wire        clk,           // 时钟信号
    input  wire        rst_n,         // 复位信号，低电平有效
    input  wire signed [15:0] number, // 输入数据
    input  wire        s_valid,       // 输入数据有效信号
    output wire        s_ready,       // 输入就绪信号
    output wire signed [15:0] complement, // 二进制补码结果
    output wire        m_valid,       // 输出数据有效信号
    input  wire        m_ready        // 输出就绪信号
);
    // 内部信号和寄存器
    reg signed [15:0] number_r;       // 输入数据寄存器
    reg         data_valid_r;         // 数据有效标志寄存器
    reg [15:0]  inverted_number;      // 按位取反结果寄存器
    reg [15:0]  complement_r;         // 计算结果寄存器
    
    // 流水线阶段控制信号
    reg stage1_valid, stage2_valid, stage3_valid;
    wire stage1_ready, stage2_ready, stage3_ready;
    
    // 反压控制逻辑：后级准备好才能前进
    assign stage3_ready = m_ready || !stage3_valid;
    assign stage2_ready = stage3_ready || !stage2_valid;
    assign stage1_ready = stage2_ready || !stage1_valid;
    assign s_ready = stage1_ready;
    
    // 第一级流水线：寄存输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            number_r <= 16'd0;
            stage1_valid <= 1'b0;
        end else if (stage1_ready) begin
            if (s_valid && s_ready) begin
                number_r <= number;
                stage1_valid <= 1'b1;
            end else begin
                stage1_valid <= 1'b0;
            end
        end
    end

    // 第二级流水线：按位取反操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inverted_number <= 16'd0;
            stage2_valid <= 1'b0;
        end else if (stage2_ready) begin
            if (stage1_valid) begin
                inverted_number <= ~number_r;
                stage2_valid <= 1'b1;
            end else begin
                stage2_valid <= 1'b0;
            end
        end
    end

    // 第三级流水线：加1操作，完成二进制补码计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            complement_r <= 16'd0;
            stage3_valid <= 1'b0;
        end else if (stage3_ready) begin
            if (stage2_valid) begin
                complement_r <= inverted_number + 16'd1;
                stage3_valid <= 1'b1;
            end else begin
                stage3_valid <= 1'b0;
            end
        end
    end
    
    // 输出赋值
    assign complement = complement_r;
    assign m_valid = stage3_valid;

endmodule