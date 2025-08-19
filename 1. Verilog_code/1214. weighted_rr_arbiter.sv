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

// 检查是否有通道有信用
always @(*) begin
    any_credit = 0;
    for(i=0; i<WIDTH; i=i+1) begin
        if(credit[i] > 0) any_credit = 1;
    end
    
    // 生成有效信号
    for(i=0; i<WIDTH; i=i+1) begin
        valid[i] = req_i[i] & (any_credit ? req_i[i] : 1'b1);
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        grant_o <= 0;
        for(i=0; i<WIDTH; i=i+1) begin
            credit[i] <= 0;
        end
    end else if(|valid) begin
        max_credit_idx = 0;
        // 找到具有最大信用的通道
        for(i=1; i<WIDTH; i=i+1) begin
            if(valid[i] && (credit[i] > credit[max_credit_idx] || !valid[max_credit_idx])) begin
                max_credit_idx = i;
            end
        end
        
        // 授予最大信用通道
        grant_o <= 1'b1 << max_credit_idx;
        
        // 更新信用: 重置已授予的通道，为其他请求通道增加权重
        for(i=0; i<WIDTH; i=i+1) begin
            if(i == max_credit_idx) begin
                credit[i] <= 0;
            end else if(req_i[i]) begin
                credit[i] <= credit[i] + weights_i[(i*W) +: W];
            end
        end
    end else begin
        grant_o <= 0;
    end
end
endmodule