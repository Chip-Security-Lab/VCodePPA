module cam_restart #(parameter WIDTH=10, DEPTH=32)(
    input clk,
    input rst_n,               // 添加复位信号
    input restart,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] data_in,
    input data_valid,          // 输入数据有效信号
    output [DEPTH-1:0] matches, // 输出匹配结果
    output reg match_valid     // 输出有效信号
);
    // 存储阵列
    reg [WIDTH-1:0] cam_entry [0:DEPTH-1];
    
    // 流水线寄存器
    reg [WIDTH-1:0] data_stage [0:2];
    reg valid_stage [0:2];
    reg restart_stage [0:2];
    
    // 阶段性匹配结果
    reg [DEPTH-1:0] partial_matches [0:2];
    reg [DEPTH-1:0] matches_reg;
    
    // 子比较结果
    wire [DEPTH-1:0] compare_result [0:2];
    
    // 写入逻辑
    always @(posedge clk) begin
        if (write_en)
            cam_entry[write_addr] <= write_data;
    end
    
    // 比较逻辑
    genvar i;
    generate
        for (i = 0; i < DEPTH; i = i + 1) begin: match_logic
            assign compare_result[0][i] = (data_stage[0][2:0] == cam_entry[i][2:0]);
            assign compare_result[1][i] = (data_stage[1][5:3] == cam_entry[i][5:3]);
            assign compare_result[2][i] = (data_stage[2][8:6] == cam_entry[i][8:6]);
        end
    endgenerate
    
    // 流水线寄存器更新
    always @(posedge clk) begin
        if (!rst_n) begin
            // 复位所有流水线寄存器
            data_stage[0] <= 0;
            data_stage[1] <= 0;
            data_stage[2] <= 0;
            valid_stage[0] <= 0;
            valid_stage[1] <= 0;
            valid_stage[2] <= 0;
            restart_stage[0] <= 0;
            restart_stage[1] <= 0;
            restart_stage[2] <= 0;
            partial_matches[0] <= {DEPTH{1'b1}};
            partial_matches[1] <= {DEPTH{1'b1}};
            partial_matches[2] <= {DEPTH{1'b1}};
            matches_reg <= 0;
            match_valid <= 0;
        end else begin
            // 第一级流水线输入
            data_stage[0] <= data_in;
            valid_stage[0] <= data_valid;
            restart_stage[0] <= restart;
            
            // 第二级流水线传递
            data_stage[1] <= data_stage[0];
            valid_stage[1] <= valid_stage[0];
            restart_stage[1] <= restart_stage[0];
            
            // 第三级流水线传递
            data_stage[2] <= data_stage[1];
            valid_stage[2] <= valid_stage[1];
            restart_stage[2] <= restart_stage[1];
            
            // 处理部分匹配结果
            if (restart_stage[0])
                partial_matches[0] <= {DEPTH{1'b1}};
            else if (valid_stage[0])
                partial_matches[0] <= compare_result[0];
                
            if (restart_stage[1])
                partial_matches[1] <= {DEPTH{1'b1}};
            else if (valid_stage[1])
                partial_matches[1] <= partial_matches[0] & compare_result[1];
                
            if (restart_stage[2])
                partial_matches[2] <= {DEPTH{1'b1}};
            else if (valid_stage[2])
                partial_matches[2] <= partial_matches[1] & compare_result[2];
                
            // 最终输出寄存器
            matches_reg <= partial_matches[2];
            match_valid <= valid_stage[2];
        end
    end
    
    // 输出赋值
    assign matches = matches_reg;
    
endmodule