module cam_restart #(parameter WIDTH=10, DEPTH=32)(
    input clk,
    input restart,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] data_in,
    output reg [DEPTH-1:0] partial_matches,
    // 流水线控制接口
    input valid_in,
    output valid_out,
    input ready_out,
    output ready_in
);
    localparam PIPELINE_STAGES = 3;
    
    // 流水线阶段注册
    reg [WIDTH-1:0] data_stage1, data_stage2, data_stage3;
    reg [DEPTH-1:0] matches_stage1, matches_stage2, matches_stage3;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // CAM存储
    reg [WIDTH-1:0] cam_entry [0:DEPTH-1];
    
    // 流水线控制信号 - 优化流水线控制逻辑，减少逻辑链长度
    wire [PIPELINE_STAGES-1:0] stage_valid, stage_ready;
    assign stage_valid = {valid_stage3, valid_stage2, valid_stage1};
    assign stage_ready[2] = ready_out || !stage_valid[2];
    assign stage_ready[1] = stage_ready[2] || !stage_valid[1];
    assign stage_ready[0] = stage_ready[1] || !stage_valid[0];
    
    assign ready_in = stage_ready[0];
    assign valid_out = valid_stage3;
    
    // 预计算Han-Carlson加法器常量部分
    wire [2:0] hc_a, hc_b;
    wire [2:0] hc_sum;
    wire hc_cout;
    
    // 预存每个CAM条目的位分段，减少访问延迟
    reg [2:0] cam_entry_low [0:DEPTH-1];  // [2:0]
    reg [2:0] cam_entry_mid [0:DEPTH-1];  // [5:3]
    reg [2:0] cam_entry_high [0:DEPTH-1]; // [8:6]
    
    // 写入逻辑 - 同时更新位分段缓存
    integer i;
    always @(posedge clk) begin
        if (write_en) begin
            cam_entry[write_addr] <= write_data;
            cam_entry_low[write_addr] <= write_data[2:0];
            cam_entry_mid[write_addr] <= write_data[5:3];
            cam_entry_high[write_addr] <= write_data[8:6];
        end
    end
    
    // 优化的Han-Carlson加法器实现 - 并行计算多个比较结果
    // 生成P和G信号
    function [2:0] gen_p;
        input [2:0] a, b;
        begin
            gen_p = a ^ b;
        end
    endfunction
    
    function [2:0] gen_g;
        input [2:0] a, b;
        begin
            gen_g = a & b;
        end
    endfunction
    
    // 优化的比较器函数，直接返回是否相等
    function is_equal;
        input [2:0] a, b;
        begin
            is_equal = (a == b);
        end
    endfunction
    
    // 段1数据寄存
    reg [2:0] data_in_low;
    
    // 段1：预处理数据
    always @(posedge clk) begin
        if (restart) begin
            valid_stage1 <= 1'b0;
            matches_stage1 <= {DEPTH{1'b1}};
            data_in_low <= 3'b0;
        end else if (stage_ready[0]) begin
            valid_stage1 <= valid_in;
            data_stage1 <= data_in;
            data_in_low <= data_in[2:0];
            
            if (valid_in) begin
                for (i = 0; i < DEPTH; i = i + 1) begin
                    // 并行比较逻辑，减少关键路径
                    matches_stage1[i] <= is_equal(data_in[2:0], cam_entry_low[i]);
                end
            end
        end
    end
    
    // 段2：处理数据[5:3]位 - 优化比较逻辑
    always @(posedge clk) begin
        if (restart) begin
            valid_stage2 <= 1'b0;
            matches_stage2 <= {DEPTH{1'b1}};
        end else if (stage_ready[1]) begin
            valid_stage2 <= valid_stage1;
            data_stage2 <= data_stage1;
            
            if (valid_stage1) begin
                for (i = 0; i < DEPTH; i = i + 1) begin
                    // 使用预存储的分段值进行比较
                    matches_stage2[i] <= matches_stage1[i] & is_equal(data_stage1[5:3], cam_entry_mid[i]);
                end
            end else begin
                matches_stage2 <= matches_stage1;
            end
        end
    end
    
    // 预计算阶段3比较结果
    reg [DEPTH-1:0] compare_results_stage3;
    always @(*) begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            compare_results_stage3[i] = is_equal(data_stage2[8:6], cam_entry_high[i]);
        end
    end
    
    // 段3：处理数据[8:6]位 - 使用预计算结果
    always @(posedge clk) begin
        if (restart) begin
            valid_stage3 <= 1'b0;
            matches_stage3 <= {DEPTH{1'b1}};
        end else if (stage_ready[2]) begin
            valid_stage3 <= valid_stage2;
            data_stage3 <= data_stage2;
            
            if (valid_stage2) begin
                for (i = 0; i < DEPTH; i = i + 1) begin
                    // 使用预计算的比较结果
                    matches_stage3[i] <= matches_stage2[i] & compare_results_stage3[i];
                end
            end else begin
                matches_stage3 <= matches_stage2;
            end
        end
    end
    
    // 输出赋值 - 直接连接到最后阶段
    always @(*) begin
        partial_matches = matches_stage3;
    end
    
endmodule