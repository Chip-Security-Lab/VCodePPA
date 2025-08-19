//SystemVerilog
module weighted_rr_arbiter #(parameter WIDTH=4, parameter W=8) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    input [WIDTH*W-1:0] weights_i,
    output reg [WIDTH-1:0] grant_o
);
    // 流水线第1级 - 输入寄存器
    reg [WIDTH-1:0] req_stage1;
    reg [WIDTH*W-1:0] weights_stage1;
    reg stage1_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            req_stage1 <= 0;
            weights_stage1 <= 0;
            stage1_valid <= 0;
        end else begin
            req_stage1 <= req_i;
            weights_stage1 <= weights_i;
            stage1_valid <= 1'b1; // 流水线启动信号
        end
    end
    
    // 流水线第1级 - 信用计算和有效信号生成
    reg [W-1:0] credit [0:WIDTH-1];
    wire [WIDTH-1:0] valid_stage1;
    wire any_credit_stage1;
    
    // 检查是否有通道有信用
    assign any_credit_stage1 = |{credit[0] > 0, credit[1] > 0, credit[2] > 0, credit[3] > 0};
    
    // 生成有效信号
    genvar i;
    generate
        for(i=0; i<WIDTH; i=i+1) begin: gen_valid
            assign valid_stage1[i] = req_stage1[i] & (any_credit_stage1 ? (credit[i] > 0) : 1'b1);
        end
    endgenerate
    
    // 流水线第1级 - 预计算信用加法
    wire [W-1:0] credit_sums_stage1 [0:WIDTH-1];
    
    generate
        for(i=0; i<WIDTH; i=i+1) begin: gen_adders
            han_carlson_adder #(.WIDTH(W)) hc_adder (
                .a(credit[i]),
                .b(weights_stage1[(i*W) +: W]),
                .cin(1'b0),
                .sum(credit_sums_stage1[i]),
                .cout()
            );
        end
    endgenerate
    
    // 流水线第1->2级 寄存器
    reg [WIDTH-1:0] valid_stage2;
    reg [WIDTH-1:0] req_stage2;
    reg [W-1:0] credit_stage2 [0:WIDTH-1];
    reg [W-1:0] credit_sums_stage2 [0:WIDTH-1];
    reg [WIDTH*W-1:0] weights_stage2;
    reg stage2_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            valid_stage2 <= 0;
            req_stage2 <= 0;
            weights_stage2 <= 0;
            stage2_valid <= 0;
            for(integer j=0; j<WIDTH; j=j+1) begin
                credit_stage2[j] <= 0;
                credit_sums_stage2[j] <= 0;
            end
        end else begin
            valid_stage2 <= valid_stage1;
            req_stage2 <= req_stage1;
            weights_stage2 <= weights_stage1;
            stage2_valid <= stage1_valid;
            for(integer j=0; j<WIDTH; j=j+1) begin
                credit_stage2[j] <= credit[j];
                credit_sums_stage2[j] <= credit_sums_stage1[j];
            end
        end
    end
    
    // 流水线第2级 - 优先级掩码计算
    reg [WIDTH-1:0] max_credit_mask_stage2;
    
    always @(*) begin
        max_credit_mask_stage2 = 0;
        for(integer j=0; j<WIDTH; j=j+1) begin
            if(valid_stage2[j]) begin
                reg valid_idx_has_max = 1'b1;
                for(integer k=0; k<WIDTH; k=k+1) begin
                    if(k != j && valid_stage2[k] && credit_stage2[k] > credit_stage2[j]) begin
                        valid_idx_has_max = 1'b0;
                    end
                end
                max_credit_mask_stage2[j] = valid_idx_has_max;
            end
        end
    end
    
    // 优先级编码的结果
    wire [$clog2(WIDTH)-1:0] max_credit_idx_stage2;
    
    encoder #(.WIDTH(WIDTH)) enc (
        .one_hot(max_credit_mask_stage2),
        .binary(max_credit_idx_stage2)
    );
    
    // 流水线第2->3级 寄存器
    reg [WIDTH-1:0] valid_stage3;
    reg [WIDTH-1:0] req_stage3;
    reg [WIDTH-1:0] max_credit_mask_stage3;
    reg [$clog2(WIDTH)-1:0] max_credit_idx_stage3;
    reg [W-1:0] credit_stage3 [0:WIDTH-1];
    reg [W-1:0] credit_sums_stage3 [0:WIDTH-1];
    reg [WIDTH*W-1:0] weights_stage3;
    reg stage3_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            valid_stage3 <= 0;
            req_stage3 <= 0;
            max_credit_mask_stage3 <= 0;
            max_credit_idx_stage3 <= 0;
            weights_stage3 <= 0;
            stage3_valid <= 0;
            for(integer j=0; j<WIDTH; j=j+1) begin
                credit_stage3[j] <= 0;
                credit_sums_stage3[j] <= 0;
            end
        end else begin
            valid_stage3 <= valid_stage2;
            req_stage3 <= req_stage2;
            max_credit_mask_stage3 <= max_credit_mask_stage2;
            max_credit_idx_stage3 <= max_credit_idx_stage2;
            weights_stage3 <= weights_stage2;
            stage3_valid <= stage2_valid;
            for(integer j=0; j<WIDTH; j=j+1) begin
                credit_stage3[j] <= credit_stage2[j];
                credit_sums_stage3[j] <= credit_sums_stage2[j];
            end
        end
    end
    
    // 流水线第3级 - 选择权重和最终授权生成
    wire [W-1:0] weight_selected_stage3;
    wire [WIDTH-1:0] grant_stage3;
    
    assign weight_selected_stage3 = weights_stage3[(max_credit_idx_stage3*W) +: W];
    assign grant_stage3 = (|valid_stage3) ? (1'b1 << max_credit_idx_stage3) : 0;
    
    // 最终输出寄存器和信用更新
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            grant_o <= 0;
            for(integer j=0; j<WIDTH; j=j+1) begin
                credit[j] <= 0;
            end
        end else if(stage3_valid && (|valid_stage3)) begin
            // 授予最大信用通道
            grant_o <= grant_stage3;
            
            // 更新信用: 重置已授予的通道，为其他请求通道增加权重
            for(integer j=0; j<WIDTH; j=j+1) begin
                if(j == max_credit_idx_stage3) begin
                    credit[j] <= 0;
                end else if(req_stage3[j]) begin
                    // 使用预计算的加法结果
                    credit[j] <= credit_sums_stage3[j];
                end
            end
        end else begin
            grant_o <= 0;
        end
    end
endmodule

// 编码器模块 - 将one-hot编码转换为二进制
module encoder #(parameter WIDTH=4) (
    input [WIDTH-1:0] one_hot,
    output reg [$clog2(WIDTH)-1:0] binary
);
    always @(*) begin
        binary = 0;
        for(integer i=0; i<WIDTH; i=i+1) begin
            if(one_hot[i]) begin
                binary = i[$clog2(WIDTH)-1:0];
            end
        end
    end
endmodule

// Han-Carlson加法器模块实现 - 内部流水线优化
module han_carlson_adder #(parameter WIDTH=8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);
    // 预处理：生成传播p和生成g信号
    wire [WIDTH-1:0] p, g;
    genvar i;
    
    // 第一阶段：预处理，计算初始p和g
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: pre_processing
            assign p[i] = a[i] ^ b[i];
            assign g[i] = a[i] & b[i];
        end
    endgenerate
    
    // 中间信号及当前进位
    wire [WIDTH:0] c;
    wire [WIDTH-1:0] pp, gp;
    assign c[0] = cin;
    
    // Han-Carlson特有的树结构并行处理
    // 第一级：初始化所有奇数位
    generate
        for (i = 1; i < WIDTH; i = i + 2) begin: odd_processing
            assign pp[i] = p[i] & p[i-1];
            assign gp[i] = g[i] | (p[i] & g[i-1]);
        end
    endgenerate
    
    // 第二级：处理偶数位
    generate
        for (i = 2; i < WIDTH; i = i + 2) begin: even_processing
            assign pp[i] = p[i] & p[i-1];
            assign gp[i] = g[i] | (p[i] & g[i-1]);
        end
    endgenerate
    
    // 第三级：计算所有进位
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: carry_generation
            if (i == 0)
                assign c[i+1] = g[i] | (p[i] & c[i]);
            else
                assign c[i+1] = gp[i] | (pp[i] & c[i-1]);
        end
    endgenerate
    
    // 后处理：生成最终和
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: sum_generation
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate
    
    // 输出进位
    assign cout = c[WIDTH];
endmodule