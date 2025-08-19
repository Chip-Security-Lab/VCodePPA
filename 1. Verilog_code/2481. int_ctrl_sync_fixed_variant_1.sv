//SystemVerilog
module int_ctrl_sync_fixed #(
    parameter WIDTH = 8
)(
    input clk, rst_n, en,
    input [WIDTH-1:0] req,
    output reg [$clog2(WIDTH)-1:0] grant
);
    // 将流水线拆分为四级，优化关键路径
    reg [WIDTH-1:0] req_stage1;
    reg [WIDTH-1:0] req_stage2;
    reg [WIDTH-1:0] req_stage3;
    
    reg [$clog2(WIDTH)-1:0] grant_stage1;
    reg [$clog2(WIDTH)-1:0] grant_stage2;
    reg [$clog2(WIDTH)-1:0] grant_stage3;
    
    reg en_stage1, en_stage2, en_stage3;
    reg high_valid_stage2, high_valid_stage3;
    
    // 第一级流水线：注册输入请求和使能信号
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            req_stage1 <= {WIDTH{1'b0}};
            en_stage1 <= 1'b0;
        end
        else begin
            req_stage1 <= req;
            en_stage1 <= en;
        end
    end
    
    // 第二级流水线：处理高位部分请求的前半部分
    // 将原来的大型组合逻辑for循环分为两部分，减少关键路径
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            req_stage2 <= {WIDTH{1'b0}};
            en_stage2 <= 1'b0;
            grant_stage1 <= {$clog2(WIDTH){1'b0}};
            high_valid_stage2 <= 1'b0;
        end
        else begin
            req_stage2 <= req_stage1;
            en_stage2 <= en_stage1;
            
            grant_stage1 <= {$clog2(WIDTH){1'b0}};
            high_valid_stage2 <= 1'b0;
            
            if(en_stage1) begin
                // 只处理高位部分的高半部分
                if(WIDTH > 4) begin
                    for(int i = WIDTH-1; i >= 3*WIDTH/4; i = i - 1) begin
                        if(req_stage1[i]) begin
                            grant_stage1 <= i[$clog2(WIDTH)-1:0];
                            high_valid_stage2 <= 1'b1;
                        end
                    end
                end
            end
        end
    end
    
    // 第三级流水线：处理高位部分请求的后半部分
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            req_stage3 <= {WIDTH{1'b0}};
            en_stage3 <= 1'b0;
            grant_stage2 <= {$clog2(WIDTH){1'b0}};
            high_valid_stage3 <= 1'b0;
        end
        else begin
            req_stage3 <= req_stage2;
            en_stage3 <= en_stage2;
            high_valid_stage3 <= high_valid_stage2;
            
            // 优先保留上一级的结果
            grant_stage2 <= grant_stage1;
            
            if(en_stage2 && !high_valid_stage2) begin
                // 只处理高位部分的低半部分
                if(WIDTH > 2) begin
                    for(int i = 3*WIDTH/4-1; i >= WIDTH/2; i = i - 1) begin
                        if(req_stage2[i]) begin
                            grant_stage2 <= i[$clog2(WIDTH)-1:0];
                            high_valid_stage3 <= 1'b1;
                        end
                    end
                end
            end
        end
    end
    
    // 第四级流水线：处理低位部分请求并确定最终优先级
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            grant_stage3 <= {$clog2(WIDTH){1'b0}};
            grant <= {$clog2(WIDTH){1'b0}};
        end
        else begin
            grant <= grant_stage3;
            
            // 优先保留上一级的结果
            grant_stage3 <= grant_stage2;
            
            if(en_stage3 && !high_valid_stage3) begin
                // 将低位部分的处理分两部分，先处理高半部分
                if(WIDTH > 1) begin
                    for(int j = WIDTH/2-1; j >= WIDTH/4; j = j - 1) begin
                        if(req_stage3[j]) grant_stage3 <= j[$clog2(WIDTH)-1:0];
                    end
                end
                
                // 然后处理最低位部分，这样有效减少了for循环的深度
                for(int j = WIDTH/4-1; j >= 0; j = j - 1) begin
                    if(req_stage3[j]) grant_stage3 <= j[$clog2(WIDTH)-1:0];
                end
            end
        end
    end
endmodule