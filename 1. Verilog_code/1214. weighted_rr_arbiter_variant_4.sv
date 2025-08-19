//SystemVerilog
module weighted_rr_arbiter #(parameter WIDTH=4, parameter W=8) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    input [WIDTH*W-1:0] weights_i,
    output reg [WIDTH-1:0] grant_o
);
    // IEEE 1364-2005 Verilog standard
    
    // 合并后的流水线级1：请求和信用处理 + 最大信用计算
    reg [WIDTH-1:0] req_stage1;
    reg [WIDTH*W-1:0] weights_stage1;
    reg [W-1:0] credit [0:WIDTH-1];
    reg [$clog2(WIDTH)-1:0] max_credit_idx_stage1;
    reg valid_stage1;
    
    // 流水线级2：授权和更新 (原流水线级3)
    reg [$clog2(WIDTH)-1:0] max_credit_idx_stage2;
    reg valid_stage2;
    
    // 流水线级1：捕获输入并计算最大信用索引 (合并原级1和级2)
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            req_stage1 <= {WIDTH{1'b0}};
            weights_stage1 <= {(WIDTH*W){1'b0}};
            valid_stage1 <= 1'b0;
            max_credit_idx_stage1 <= {$clog2(WIDTH){1'b0}};
        end else begin
            req_stage1 <= req_i;
            weights_stage1 <= weights_i;
            valid_stage1 <= |req_i;
            
            // 最大信用算法直接在第一级流水线中处理
            if(|req_i) begin
                reg [$clog2(WIDTH)-1:0] local_max_idx;
                reg [W-1:0] local_max_credit;
                reg found_valid;
                
                found_valid = 1'b0;
                local_max_idx = {$clog2(WIDTH){1'b0}};
                local_max_credit = {W{1'b0}};
                
                for(integer i=0; i<WIDTH; i=i+1) begin
                    if(req_i[i]) begin
                        if(!found_valid || credit[i] > local_max_credit) begin
                            found_valid = 1'b1;
                            local_max_idx = i[$clog2(WIDTH)-1:0];
                            local_max_credit = credit[i];
                        end
                    end
                end
                
                max_credit_idx_stage1 <= local_max_idx;
            end
        end
    end
    
    // 流水线级2：授权和前递 (对应原流水线级3)
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            max_credit_idx_stage2 <= {$clog2(WIDTH){1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            max_credit_idx_stage2 <= max_credit_idx_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出授权和信用更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
            for(integer i=0; i<WIDTH; i=i+1) begin
                credit[i] <= {W{1'b0}};
            end
        end else begin
            // 生成授权信号
            if(valid_stage2) begin
                grant_o <= {{(WIDTH-1){1'b0}}, 1'b1} << max_credit_idx_stage2;
            end else begin
                grant_o <= {WIDTH{1'b0}};
            end
            
            // 更新信用系统 - 结合当前输入实现前递
            if(valid_stage2) begin
                for(integer i=0; i<WIDTH; i=i+1) begin
                    if(i == max_credit_idx_stage2) begin
                        credit[i] <= {W{1'b0}};
                    end else if(req_i[i]) begin
                        // 从当前输入直接获取权重实现前递
                        credit[i] <= credit[i] + weights_i[i*W+:W];
                    end
                end
            end
        end
    end
endmodule