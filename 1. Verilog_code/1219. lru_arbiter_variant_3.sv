//SystemVerilog
module lru_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    reg [WIDTH-1:0] usage [0:WIDTH-1];
    reg [WIDTH-1:0] req_reg;
    reg [$clog2(WIDTH)-1:0] lru_idx;
    integer i;
    
    // 寄存输入请求信号
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            req_reg <= {WIDTH{1'b0}};
        end else begin
            req_reg <= req_i;
        end
    end
    
    // 重置usage计数器逻辑
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0; i<WIDTH; i=i+1) begin
                usage[i] <= 4'b0001 << i;
            end
        end
    end
    
    // 计算LRU索引的组合逻辑
    always @(*) begin
        lru_idx = 0;
        for(i=1; i<WIDTH; i=i+1) begin
            if(usage[i] < usage[lru_idx] && req_reg[i]) 
                lru_idx = i;
        end
    end
    
    // 更新LRU使用计数器
    always @(posedge clk) begin
        if(rst_n) begin
            usage[lru_idx] <= {1'b1, usage[lru_idx][WIDTH-1:1]};
        end
    end
    
    // 生成grant输出信号
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
        end else begin
            grant_o <= (1'b1 << lru_idx);
        end
    end
endmodule