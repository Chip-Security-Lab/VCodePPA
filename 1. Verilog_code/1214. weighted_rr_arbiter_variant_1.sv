//SystemVerilog
module weighted_rr_arbiter #(parameter WIDTH=4, parameter W=8) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    input [WIDTH*W-1:0] weights_i,
    output reg [WIDTH-1:0] grant_o
);
    // 流水线阶段1: 请求和信用值计算信号
    reg [WIDTH-1:0] req_stage1;
    reg [WIDTH*W-1:0] weights_stage1;
    reg [W-1:0] credit [0:WIDTH-1];
    reg [WIDTH-1:0] has_credit_stage1;
    reg any_credit_stage1;
    reg [WIDTH-1:0] valid_stage1;
    reg stage1_valid;
    
    // 流水线阶段2: 最大信用计算信号
    reg [WIDTH-1:0] req_stage2;
    reg [WIDTH-1:0] valid_stage2;
    reg [WIDTH-1:0] max_credit_mask_stage2;
    reg [$clog2(WIDTH)-1:0] max_credit_idx_stage2;
    reg stage2_valid;
    
    // 流水线阶段3: 授予和信用更新信号
    reg [WIDTH-1:0] grant_stage3;
    reg [WIDTH-1:0] max_credit_mask_stage3;
    reg [WIDTH-1:0] req_stage3;
    reg stage3_valid;
    
    integer i;

    // 阶段1: 计算信用状态和有效请求
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            req_stage1 <= {WIDTH{1'b0}};
            weights_stage1 <= {(WIDTH*W){1'b0}};
            has_credit_stage1 <= {WIDTH{1'b0}};
            any_credit_stage1 <= 1'b0;
            valid_stage1 <= {WIDTH{1'b0}};
            stage1_valid <= 1'b0;
        end else begin
            req_stage1 <= req_i;
            weights_stage1 <= weights_i;
            
            for(i=0; i<WIDTH; i=i+1) begin
                has_credit_stage1[i] <= (credit[i] > 0);
            end
            any_credit_stage1 <= |(req_i & {WIDTH{1'b1}}); // Any request
            valid_stage1 <= req_i & (|(req_i & {WIDTH{1'b1}}) ? has_credit_stage1 : {WIDTH{1'b1}});
            stage1_valid <= 1'b1; // Stage always valid after reset
        end
    end

    // 阶段2: 查找最大信用通道
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            req_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= {WIDTH{1'b0}};
            max_credit_mask_stage2 <= {WIDTH{1'b0}};
            max_credit_idx_stage2 <= {$clog2(WIDTH){1'b0}};
            stage2_valid <= 1'b0;
        end else if(stage1_valid) begin
            req_stage2 <= req_stage1;
            valid_stage2 <= valid_stage1;
            
            // 找出具有最大信用的有效通道
            max_credit_mask_stage2 <= {WIDTH{1'b0}};
            max_credit_idx_stage2 <= {$clog2(WIDTH){1'b0}};
            
            for(i=0; i<WIDTH; i=i+1) begin
                if(valid_stage1[i]) begin
                    if(max_credit_mask_stage2 == 0) begin
                        max_credit_mask_stage2[i] <= 1'b1;
                        max_credit_idx_stage2 <= i[$clog2(WIDTH)-1:0];
                    end else if(credit[i] > credit[max_credit_idx_stage2]) begin
                        max_credit_mask_stage2 <= {WIDTH{1'b0}};
                        max_credit_mask_stage2[i] <= 1'b1;
                        max_credit_idx_stage2 <= i[$clog2(WIDTH)-1:0];
                    end
                end
            end
            
            stage2_valid <= stage1_valid;
        end
    end

    // 阶段3: 生成授予信号并更新信用
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            grant_stage3 <= {WIDTH{1'b0}};
            max_credit_mask_stage3 <= {WIDTH{1'b0}};
            req_stage3 <= {WIDTH{1'b0}};
            stage3_valid <= 1'b0;
        end else if(stage2_valid) begin
            grant_stage3 <= |valid_stage2 ? max_credit_mask_stage2 : {WIDTH{1'b0}};
            max_credit_mask_stage3 <= max_credit_mask_stage2;
            req_stage3 <= req_stage2;
            stage3_valid <= stage2_valid;
        end
    end
    
    // 更新信用值并生成输出
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
            for(i=0; i<WIDTH; i=i+1) begin
                credit[i] <= weights_i[(i*W) +: W]; // 初始化信用为权重
            end
        end else if(stage3_valid) begin
            grant_o <= grant_stage3;
            
            // 更新信用值
            for(i=0; i<WIDTH; i=i+1) begin
                if(max_credit_mask_stage3[i]) begin
                    credit[i] <= weights_stage1[(i*W) +: W]; // 刷新信用
                end else if(req_stage3[i]) begin
                    credit[i] <= credit[i] + weights_stage1[(i*W) +: W]; // 累积信用
                end
            end
        end
    end
endmodule