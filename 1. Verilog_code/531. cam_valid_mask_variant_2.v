module cam_valid_mask #(
    parameter WIDTH=12,
    parameter DEPTH=64
)(
    input                       clk,
    input                       write_en,
    input  [$clog2(DEPTH)-1:0]  write_addr,
    input  [WIDTH-1:0]          write_data,
    input  [WIDTH-1:0]          data_in,
    input  [DEPTH-1:0]          valid_mask,
    output [DEPTH-1:0]          match_lines
);
    // CAM存储数组
    reg [WIDTH-1:0] cam_table [0:DEPTH-1];
    
    // 流水线级寄存器
    reg [WIDTH-1:0]  data_in_reg;        // 寄存输入数据，减少扇出
    reg [DEPTH-1:0]  valid_mask_reg;     // 寄存有效掩码
    reg [DEPTH-1:0]  raw_matches_stage1; // 第一级比较结果
    reg [DEPTH-1:0]  match_result;       // 最终匹配结果
    
    // 1. 输入寄存阶段 - 捕获输入数据
    always @(posedge clk) begin
        data_in_reg    <= data_in;
        valid_mask_reg <= valid_mask;
    end
    
    // 2. CAM表更新逻辑 - 写入操作
    always @(posedge clk) begin
        if (write_en) begin
            cam_table[write_addr] <= write_data;
        end
    end
    
    // 3. 比较阶段 - 并行比较逻辑，分块实现减少路径深度
    genvar g;
    generate
        for(g=0; g<DEPTH; g=g+1) begin: compare_gen
            always @(posedge clk) begin
                raw_matches_stage1[g] <= (cam_table[g] == data_in_reg);
            end
        end
    endgenerate
    
    // 4. 掩码应用阶段 - 应用有效性掩码并寄存结果
    always @(posedge clk) begin
        match_result <= raw_matches_stage1 & valid_mask_reg;
    end
    
    // 输出结果
    assign match_lines = match_result;
    
endmodule