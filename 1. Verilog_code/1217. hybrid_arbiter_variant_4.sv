//SystemVerilog - IEEE 1364-2005
module hybrid_arbiter #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);

    // 将仲裁逻辑分为高优先级(固定优先级)和低优先级(轮询)两部分
    reg [1:0] rr_ptr;              // 轮询指针
    reg [1:0] rr_ptr_next;         // 下一个轮询指针值
    
    // 数据流分段信号
    reg [WIDTH-1:0] hp_grant;      // 高优先级仲裁结果
    reg [WIDTH-1:0] lp_grant;      // 低优先级仲裁结果
    reg hp_valid;                  // 高优先级仲裁有效标志
    
    // 轮询仲裁逻辑计算信号
    wire [1:0] req_low;            // 低优先级请求
    wire [1:0] shifted_req;        // 根据轮询指针移位后的请求
    wire [1:0] masked_req;         // 轮询过程中的掩码请求
    wire [1:0] lp_grant_idx;       // 低优先级仲裁选择的索引
    wire lp_valid;                 // 低优先级仲裁有效标志
    
    // 第一阶段：分离高优先级和低优先级请求
    assign req_low = req_i[1:0];
    
    // 第二阶段：高优先级仲裁逻辑 - 固定优先级处理高位请求
    // 仅处理高优先级信号(bit 2-3)的仲裁
    always @(*) begin
        hp_valid = 1'b0;
        hp_grant = {WIDTH{1'b0}};
        
        if (req_i[2]) begin
            hp_grant = 4'b0100;  // 优先为bit-2
            hp_valid = 1'b1;
        end else if (req_i[3]) begin
            hp_grant = 4'b1000;  // 其次为bit-3
            hp_valid = 1'b1;
        end
    end
    
    // 第三阶段：低优先级轮询仲裁逻辑相关信号生成
    // 生成移位后的请求信号
    assign shifted_req[0] = req_low[(rr_ptr + 2'd0) % 2'd2];
    assign shifted_req[1] = req_low[(rr_ptr + 2'd1) % 2'd2];
    
    // 计算优先级掩码 - 优先选择第一个有效的请求
    assign masked_req[0] = shifted_req[0];
    assign masked_req[1] = shifted_req[1] & ~shifted_req[0];
    
    // 确定低优先级有效信号
    assign lp_valid = |masked_req;
    
    // 根据掩码选择索引
    assign lp_grant_idx[0] = masked_req[0] ? (rr_ptr + 2'd0) % 2'd2 : 
                             masked_req[1] ? (rr_ptr + 2'd1) % 2'd2 : 2'd0;
    assign lp_grant_idx[1] = 1'b0; // 低2位仲裁，高位始终为0
    
    // 单独处理低优先级仲裁信号生成
    always @(*) begin
        lp_grant = {WIDTH{1'b0}};
        
        if (lp_valid) begin
            lp_grant = 1'b1 << lp_grant_idx;
        end
    end
    
    // 单独计算轮询指针下一个值
    always @(*) begin
        rr_ptr_next = rr_ptr;
        
        if (lp_valid) begin
            rr_ptr_next = (lp_grant_idx + 2'd1) % 2'd2;
        end
    end
    
    // 轮询指针更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rr_ptr <= 2'd0;
        end else if (lp_valid && !hp_valid) begin
            rr_ptr <= rr_ptr_next;
        end
    end
    
    // 最终输出仲裁结果选择
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
        end else if (hp_valid) begin
            grant_o <= hp_grant;
        end else if (lp_valid) begin
            grant_o <= lp_grant;
        end else begin
            grant_o <= {WIDTH{1'b0}};
        end
    end

endmodule