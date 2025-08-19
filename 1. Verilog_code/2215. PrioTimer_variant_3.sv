//SystemVerilog
module PrioTimer #(parameter N=4) (
    input clk, rst_n,
    input [N-1:0] req,
    output reg [$clog2(N)-1:0] grant
);
    // 阶段1: 计数器更新部分
    reg [7:0] cnt_stage1 [0:N-1];
    reg [7:0] cnt_stage2 [0:N-1];
    reg [N-1:0] req_stage1;
    
    // 阶段2: 优先级选择部分
    reg [$clog2(N)-1:0] grant_stage2;
    reg valid_stage1, valid_stage2;
    
    integer i;
    
    // 阶段1: 计数器状态控制
    always @(posedge clk) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            req_stage1 <= {N{1'b0}};
        end
        else begin
            valid_stage1 <= 1'b1;
            req_stage1 <= req;
        end
    end
    
    // 阶段1: 计数器更新逻辑-重置部分
    always @(posedge clk) begin
        if (!rst_n) begin
            for(i=0; i<N; i=i+1) begin
                cnt_stage1[i] <= 8'h00;
            end
        end
    end
    
    // 阶段1: 计数器更新逻辑-递增部分
    genvar g;
    generate
        for(g=0; g<N; g=g+1) begin : cnt_update_gen
            always @(posedge clk) begin
                if (rst_n && req[g]) begin
                    cnt_stage1[g] <= cnt_stage1[g] + 8'h01;
                end
            end
        end
    endgenerate
    
    // 阶段1和阶段2之间的流水线状态控制
    always @(posedge clk) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end
        else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 阶段1和阶段2之间的流水线数据传输
    always @(posedge clk) begin
        if (!rst_n) begin
            for(i=0; i<N; i=i+1) begin
                cnt_stage2[i] <= 8'h00;
            end
        end
        else begin
            for(i=0; i<N; i=i+1) begin
                cnt_stage2[i] <= cnt_stage1[i];
            end
        end
    end
    
    // 阶段2: 优先级选择逻辑状态变量
    reg [$clog2(N)-1:0] highest_priority;
    reg found_priority;
    
    // 阶段2: 找寻最高优先级逻辑
    always @(posedge clk) begin
        if (!rst_n) begin
            highest_priority <= {$clog2(N){1'b0}};
            found_priority <= 1'b0;
        end
        else if (valid_stage2) begin
            highest_priority <= {$clog2(N){1'b0}};
            found_priority <= 1'b0;
        end
    end
    
    // 阶段2: 逐位检查超过阈值的计数器
    always @(posedge clk) begin
        if (rst_n && valid_stage2) begin
            for(i=N-1; i>=0; i=i-1) begin
                if (!found_priority && (cnt_stage2[i] > 8'h7F)) begin
                    highest_priority <= i[$clog2(N)-1:0];
                    found_priority <= 1'b1;
                end
            end
        end
    end
    
    // 阶段2: 更新阶段2授权结果
    always @(posedge clk) begin
        if (!rst_n) begin
            grant_stage2 <= {$clog2(N){1'b0}};
        end
        else if (valid_stage2) begin
            grant_stage2 <= highest_priority;
        end
    end
    
    // 输出寄存器
    always @(posedge clk) begin
        if (!rst_n) begin
            grant <= {$clog2(N){1'b0}};
        end
        else begin
            grant <= grant_stage2;
        end
    end
endmodule