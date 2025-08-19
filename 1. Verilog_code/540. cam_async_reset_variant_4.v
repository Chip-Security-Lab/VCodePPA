module cam_async_reset #(parameter WIDTH=4, DEPTH=8)(
    input clk,
    input async_rst,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] search_data,
    input valid_in,
    output valid_out,
    output [DEPTH-1:0] match_lines
);
    // CAM存储
    reg [WIDTH-1:0] cam_entries [0:DEPTH-1];
    
    // 第一级流水线 - 输入和搜索数据寄存
    reg [WIDTH-1:0] search_data_stage1;
    reg valid_stage1;
    
    // 第二级流水线 - 比较结果寄存
    reg [DEPTH-1:0] match_lines_stage2;
    reg valid_stage2;
    
    // 临时比较结果线和中间变量
    reg [DEPTH-1:0] compare_results;
    
    // 写入流程中的中间变量
    reg write_active;
    reg [$clog2(DEPTH)-1:0] current_write_addr;
    reg [WIDTH-1:0] current_write_data;
    
    // 写入逻辑，异步复位
    integer i;
    always @(posedge clk or posedge async_rst) begin
        if(async_rst) begin
            // 复位所有CAM条目
            for(i=0; i<DEPTH; i=i+1)
                cam_entries[i] <= {WIDTH{1'b0}};
            // 重置写入中间变量
            write_active <= 1'b0;
            current_write_addr <= {$clog2(DEPTH){1'b0}};
            current_write_data <= {WIDTH{1'b0}};
        end 
        else begin
            // 捕获写入信号和数据
            write_active <= write_en;
            if (write_en) begin
                current_write_addr <= write_addr;
                current_write_data <= write_data;
                // 写入操作
                cam_entries[write_addr] <= write_data;
            end
        end
    end
    
    // 第一级流水线寄存器 - 捕获搜索数据
    always @(posedge clk or posedge async_rst) begin
        if(async_rst) begin
            search_data_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end 
        else begin
            search_data_stage1 <= search_data;
            valid_stage1 <= valid_in;
        end
    end
    
    // 比较逻辑 - 使用多级条件结构
    always @(*) begin
        // 默认初始化比较结果
        for(i=0; i<DEPTH; i=i+1)
            compare_results[i] = 1'b0;
            
        // 分步比较每个条目
        for(i=0; i<DEPTH; i=i+1) begin
            // 首先检查是否需要进行前递
            if (write_active && (current_write_addr == i)) begin
                // 如果前递有效，则比较写入数据
                if (current_write_data == search_data_stage1)
                    compare_results[i] = 1'b1;
                else
                    compare_results[i] = 1'b0;
            end
            else begin
                // 否则使用存储的数据进行比较
                if (cam_entries[i] == search_data_stage1)
                    compare_results[i] = 1'b1;
                else
                    compare_results[i] = 1'b0;
            end
        end
    end
    
    // 第二级流水线寄存器 - 捕获比较结果
    always @(posedge clk or posedge async_rst) begin
        if(async_rst) begin
            match_lines_stage2 <= {DEPTH{1'b0}};
            valid_stage2 <= 1'b0;
        end 
        else begin
            match_lines_stage2 <= compare_results;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 连接输出
    assign match_lines = match_lines_stage2;
    assign valid_out = valid_stage2;
    
    // 前递控制变量
    reg [DEPTH-1:0] forwarding_enable;
    reg [DEPTH-1:0] write_match;
    reg [WIDTH-1:0] prev_search_data;
    
    // 更新前递控制逻辑
    always @(posedge clk or posedge async_rst) begin
        if(async_rst) begin
            forwarding_enable <= {DEPTH{1'b0}};
            write_match <= {DEPTH{1'b0}};
            prev_search_data <= {WIDTH{1'b0}};
        end 
        else begin
            // 保存上一周期的搜索数据，用于检测变化
            prev_search_data <= search_data;
            
            // 更新每个条目的前递启用状态
            for(i=0; i<DEPTH; i=i+1) begin
                // 检查是否需要启用前递
                if (write_en && (write_addr == i)) begin
                    forwarding_enable[i] <= 1'b1;
                    // 检查写入数据是否与当前搜索数据匹配
                    if (write_data == search_data)
                        write_match[i] <= 1'b1;
                    else
                        write_match[i] <= 1'b0;
                end
                else begin
                    forwarding_enable[i] <= 1'b0;
                    write_match[i] <= 1'b0;
                end
            end
        end
    end
    
endmodule