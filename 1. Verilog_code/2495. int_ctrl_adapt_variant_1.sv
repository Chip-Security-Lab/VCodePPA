//SystemVerilog
module int_ctrl_adapt #(
    parameter N = 4
)(
    input                   clk,
    input                   rst,
    input      [N-1:0]      req,
    input      [N-1:0]      service_time,
    output reg [N-1:0]      grant
);
    // 阶段1: 输入信号缓冲 - 减少高扇出影响
    reg [N-1:0] req_stage1;
    reg [N-1:0] service_time_stage1;
    
    // 阶段2: 信号处理缓冲
    reg [N-1:0] req_stage2;
    reg [N-1:0] service_time_stage2;
    
    // 历史服务时间追踪
    reg [7:0] hist_counter[0:N-1];
    
    // 优先级控制信号
    reg [N-1:0] priority_mask;
    reg [7:0] min_service_time;
    reg [3:0] selected_channel;
    
    // 第一级寄存器: 输入信号缓冲
    always @(posedge clk) begin
        if (rst) begin
            req_stage1 <= {N{1'b0}};
            service_time_stage1 <= {N{1'b0}};
        end else begin
            req_stage1 <= req;
            service_time_stage1 <= service_time;
        end
    end
    
    // 第二级寄存器: 继续缓冲处理信号
    always @(posedge clk) begin
        if (rst) begin
            req_stage2 <= {N{1'b0}};
            service_time_stage2 <= {N{1'b0}};
        end else begin
            req_stage2 <= req_stage1;
            service_time_stage2 <= service_time_stage1;
        end
    end
    
    // 历史服务时间管理 - 更新追踪数据
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1)
                hist_counter[i] <= 8'hFF;
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                if (req_stage2[i] && service_time_stage2[i] && (hist_counter[i] > service_time_stage2[i]))
                    hist_counter[i] <= service_time_stage2[i];
            end
        end
    end
    
    // 优先级评估 - 计算最小服务时间通道
    integer j;
    always @(posedge clk) begin
        if (rst) begin
            min_service_time <= 8'hFF;
            selected_channel <= 4'h0;
            priority_mask <= {N{1'b0}};
        end else begin
            // 扁平化结构：初始化和寻找最小服务时间
            min_service_time <= 8'hFF;
            selected_channel <= 4'h0;
            priority_mask <= {N{1'b0}};
            
            // 遍历所有通道进行优先级评估
            for (j = 0; j < N; j = j + 1) begin
                if (req_stage2[j] && hist_counter[j] < min_service_time) begin
                    min_service_time <= hist_counter[j];
                    selected_channel <= j;
                end
            end
            
            // 标记优先通道 - 扁平化结构
            for (j = 0; j < N; j = j + 1) begin
                if (req_stage2[j] && (hist_counter[j] == min_service_time || j == 0))
                    priority_mask[j] <= 1'b1;
            end
        end
    end
    
    // 授权生成 - 基于优先级掩码
    always @(posedge clk) begin
        if (rst)
            grant <= {N{1'b0}};
        else
            grant <= priority_mask;
    end
endmodule