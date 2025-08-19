//SystemVerilog
module int_ctrl_adapt #(
    parameter N = 4
)(
    input clk, rst,
    input [N-1:0] req,
    input [N-1:0] service_time,
    output reg [N-1:0] grant
);
    // 历史服务时间计数器
    reg [7:0] hist_counter[0:N-1];
    // 预计算最低服务时间标志
    reg [N-1:0] is_min_service;
    // 预计算是否需要更新历史计数器
    reg [N-1:0] need_update;
    // 中间变量，用于比较服务时间
    reg is_smaller;
    
    integer i, j;
    
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < N; i = i + 1) begin
                hist_counter[i] <= 8'hFF;
                is_min_service[i] <= 1'b0;
            end
            grant <= 0;
            need_update <= 0;
        end else begin
            // 第一阶段：计算需要更新的计数器
            for(i = 0; i < N; i = i + 1) begin
                // 分解条件判断
                if (req[i]) begin
                    if (service_time[i]) begin
                        if (hist_counter[i] > service_time[i]) begin
                            need_update[i] <= 1'b1;
                        end else begin
                            need_update[i] <= 1'b0;
                        end
                    end else begin
                        need_update[i] <= 1'b0;
                    end
                end else begin
                    need_update[i] <= 1'b0;
                end
            end
            
            // 第二阶段：更新历史计数器
            for(i = 0; i < N; i = i + 1) begin
                if (need_update[i]) begin
                    hist_counter[i] <= service_time[i];
                end
            end
            
            // 第三阶段：确定最小服务时间
            for(i = 0; i < N; i = i + 1) begin
                // 初始设置
                if (i == 0) begin
                    is_min_service[i] <= req[i] ? 1'b1 : 1'b0;
                end else begin
                    // 默认认为当前请求可能是最小的
                    is_min_service[i] <= req[i] ? 1'b1 : 1'b0;
                    
                    // 检查是否有更小的值
                    if (req[i]) begin
                        for(j = 0; j < i; j = j + 1) begin
                            is_smaller = 1'b0;
                            
                            // 判断j是否有效且服务时间更小
                            if (req[j]) begin
                                if (hist_counter[j] < hist_counter[i]) begin
                                    is_smaller = 1'b1;
                                end
                            end
                            
                            // 如果找到更小的，设置当前不是最小
                            if (is_smaller) begin
                                is_min_service[i] <= 1'b0;
                            end
                        end
                    end
                end
            end
            
            // 第四阶段：根据最小服务时间授予
            for(i = 0; i < N; i = i + 1) begin
                grant[i] <= req[i] && is_min_service[i];
            end
        end
    end
endmodule