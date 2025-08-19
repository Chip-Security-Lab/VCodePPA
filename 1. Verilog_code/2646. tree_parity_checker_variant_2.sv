//SystemVerilog
module tree_parity_checker (
    input clk,
    input rst_n,
    input req_in,
    input [31:0] data,
    output ack_in,
    output req_out,
    output parity,
    input ack_out
);
    wire [15:0] stage1_result;
    wire [7:0]  stage2_result;
    wire [3:0]  stage3_result;
    wire [1:0]  stage4_result;
    reg parity_r;
    reg req_out_r;
    reg data_valid;
    
    // 握手信号处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid <= 1'b0;
            req_out_r <= 1'b0;
        end else begin
            // 接收输入数据
            if (req_in && ack_in) begin
                data_valid <= 1'b1;
            end
            
            // 发送输出结果
            if (data_valid && !req_out_r) begin
                req_out_r <= 1'b1;
            end else if (req_out_r && ack_out) begin
                req_out_r <= 1'b0;
                data_valid <= 1'b0;
            end
        end
    end
    
    // 输入接口握手信号
    assign ack_in = !data_valid;
    
    // 输出接口握手信号
    assign req_out = req_out_r;
    
    // 第一级异或操作
    parity_stage #(
        .WIDTH(32),
        .REDUCTION(2)
    ) stage1 (
        .data_in(data),
        .data_out(stage1_result)
    );
    
    // 第二级异或操作
    parity_stage #(
        .WIDTH(16),
        .REDUCTION(2)
    ) stage2 (
        .data_in(stage1_result),
        .data_out(stage2_result)
    );
    
    // 第三级异或操作
    parity_stage #(
        .WIDTH(8),
        .REDUCTION(2)
    ) stage3 (
        .data_in(stage2_result),
        .data_out(stage3_result)
    );
    
    // 第四级异或操作
    parity_stage #(
        .WIDTH(4),
        .REDUCTION(2)
    ) stage4 (
        .data_in(stage3_result),
        .data_out(stage4_result)
    );
    
    // 奇偶校验逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_r <= 1'b0;
        end else if (req_in && ack_in) begin
            parity_r <= ^stage4_result;
        end
    end
    
    // 输出奇偶校验结果
    assign parity = parity_r;
endmodule

// 参数化奇偶校验计算阶段模块
module parity_stage #(
    parameter WIDTH = 32,      // 输入数据宽度
    parameter REDUCTION = 2    // 归约因子，默认为2表示减半
)(
    input [WIDTH-1:0] data_in,
    output [(WIDTH/REDUCTION)-1:0] data_out
);
    genvar i;
    generate
        for (i = 0; i < WIDTH/REDUCTION; i = i + 1) begin : xor_units
            assign data_out[i] = ^data_in[(i+1)*REDUCTION-1:i*REDUCTION];
        end
    endgenerate
endmodule