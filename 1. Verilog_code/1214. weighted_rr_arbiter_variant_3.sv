//SystemVerilog
module weighted_rr_arbiter #(parameter WIDTH=4, parameter W=8) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    input [WIDTH*W-1:0] weights_i,
    output reg [WIDTH-1:0] grant_o
);
    reg [W-1:0] credit [0:WIDTH-1];
    reg [WIDTH-1:0] valid;
    integer i;
    reg any_credit;
    integer max_credit_idx;
    reg [W-1:0] next_credit [0:WIDTH-1];
    reg [WIDTH-1:0] next_grant;
    
    // 检查是否有通道有信用
    always @(*) begin
        any_credit = 1'b0;
        for(i=0; i<WIDTH; i=i+1) begin
            any_credit = any_credit | (|credit[i]);
        end
        
        // 生成有效信号 - 使用显式多路复用器结构
        for(i=0; i<WIDTH; i=i+1) begin
            valid[i] = req_i[i] & (any_credit ? req_i[i] : 1'b1);
        end
    end
    
    // 曼彻斯特进位链加法器实现
    function [W-1:0] manchester_carry_adder;
        input [W-1:0] a;
        input [W-1:0] b;
        
        reg [W-1:0] p; // 传播信号
        reg [W-1:0] g; // 生成信号
        reg [W:0] c;   // 进位信号
        reg [W-1:0] sum;
        integer j;
        
        begin
            // 第一阶段：计算传播和生成信号
            for(j=0; j<W; j=j+1) begin
                p[j] = a[j] ^ b[j];
                g[j] = a[j] & b[j];
            end
            
            // 第二阶段：计算进位信号
            c[0] = 1'b0;
            for(j=0; j<W; j=j+1) begin
                c[j+1] = g[j] | (p[j] & c[j]);
            end
            
            // 第三阶段：计算最终和
            for(j=0; j<W; j=j+1) begin
                sum[j] = p[j] ^ c[j];
            end
            
            manchester_carry_adder = sum;
        end
    endfunction
    
    // 使用组合逻辑计算下一状态
    always @(*) begin
        // 默认保持当前状态
        next_grant = {WIDTH{1'b0}};
        for(i=0; i<WIDTH; i=i+1) begin
            next_credit[i] = credit[i];
        end
        
        // 计算下一状态逻辑
        if(|valid) begin
            max_credit_idx = 0;
            // 找到具有最大信用的通道
            for(i=1; i<WIDTH; i=i+1) begin
                if(valid[i]) begin
                    if(!valid[max_credit_idx]) begin
                        max_credit_idx = i;
                    end else if(credit[i] > credit[max_credit_idx]) begin
                        max_credit_idx = i;
                    end
                end
            end
            
            // 授予最大信用通道
            next_grant = (1'b1 << max_credit_idx);
            
            // 更新信用: 重置已授予的通道，为其他请求通道增加权重
            for(i=0; i<WIDTH; i=i+1) begin
                if(i == max_credit_idx) begin
                    next_credit[i] = {W{1'b0}};
                end else if(req_i[i]) begin
                    // 使用曼彻斯特进位链加法器进行加法运算
                    next_credit[i] = manchester_carry_adder(credit[i], weights_i[(i*W) +: W]);
                end
            end
        end
    end
    
    // 寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
            for(i=0; i<WIDTH; i=i+1) begin
                credit[i] <= {W{1'b0}};
            end
        end else begin
            grant_o <= next_grant;
            for(i=0; i<WIDTH; i=i+1) begin
                credit[i] <= next_credit[i];
            end
        end
    end
endmodule