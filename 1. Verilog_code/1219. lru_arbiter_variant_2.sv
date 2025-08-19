//SystemVerilog
module lru_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    // 使用状态记录
    reg [WIDTH-1:0] usage [0:WIDTH-1];
    
    // LRU计算结果
    reg [1:0] lru_idx;  // 优化位宽为实际需要的2位
    reg update_needed;
    
    // 复位逻辑与初始化
    always @(posedge clk or negedge rst_n) begin
        integer i;
        if(!rst_n) begin
            for(i=0; i<WIDTH; i=i+1) begin
                usage[i] <= 4'b0001 << i;
            end
        end else if(update_needed) begin
            // 只在需要更新时修改使用情况记录
            usage[lru_idx] <= {1'b1, usage[lru_idx][WIDTH-1:1]};
        end
    end
    
    // LRU计算逻辑 - 确定最久未使用的请求
    always @(*) begin
        // 默认初始化
        lru_idx = 0;
        update_needed = 1'b0;
        
        // 优化为级联逻辑，使综合器能更好地优化
        if(req_i[0]) begin
            lru_idx = 2'd0;
            update_needed = 1'b1;
        end
        
        if(req_i[1] && (usage[1] < usage[lru_idx] || !update_needed)) begin
            lru_idx = 2'd1;
            update_needed = 1'b1;
        end
        
        if(req_i[2] && (usage[2] < usage[lru_idx] || !update_needed)) begin
            lru_idx = 2'd2;
            update_needed = 1'b1;
        end
        
        if(req_i[3] && (usage[3] < usage[lru_idx] || !update_needed)) begin
            lru_idx = 2'd3;
            update_needed = 1'b1;
        end
    end
    
    // 授权输出生成逻辑
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
        end else if(update_needed) begin
            grant_o <= (1'b1 << lru_idx);
        end else begin
            grant_o <= {WIDTH{1'b0}};
        end
    end
    
endmodule