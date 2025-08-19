module cam_restart #(parameter WIDTH=10, DEPTH=32)(
    input clk,
    input restart,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] data_in,
    input data_valid,                      // 输入数据有效信号
    output reg data_ready,                 // 流水线就绪信号
    output reg [DEPTH-1:0] partial_matches,
    output reg matches_valid               // 输出结果有效信号
);
    // 流水线阶段寄存器
    reg [WIDTH-1:0] data_stage1, data_stage2, data_stage3;
    reg [DEPTH-1:0] partial_matches_stage1, partial_matches_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // CAM存储
    reg [WIDTH-1:0] cam_entry [0:DEPTH-1];
    
    // 写入逻辑
    always @(posedge clk) begin
        if (write_en)
            cam_entry[write_addr] <= write_data;
    end
    
    // 流水线控制逻辑
    always @(posedge clk) begin
        if (restart) begin
            data_ready <= 1'b1;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            matches_valid <= 1'b0;
        end else begin
            // 输入准备好接收新数据当有空闲流水线段时
            data_ready <= ~valid_stage1 | (~valid_stage2 & valid_stage1);
            
            // 流水线有效信号传递
            if (data_valid & data_ready) begin
                valid_stage1 <= 1'b1;
            end else if (valid_stage2 | ~valid_stage1) begin
                valid_stage1 <= 1'b0;
            end
            
            valid_stage2 <= valid_stage1;
            valid_stage3 <= valid_stage2;
            matches_valid <= valid_stage3;
        end
    end
    
    // 流水线第一级 - 加载数据并比较低3位
    integer i;
    always @(posedge clk) begin
        if (restart) begin
            data_stage1 <= 'b0;
            partial_matches_stage1 <= {DEPTH{1'b1}};
        end else if (data_valid & data_ready) begin
            data_stage1 <= data_in;
            
            for (i = 0; i < DEPTH; i = i + 1) begin
                partial_matches_stage1[i] <= (data_in[2:0] == cam_entry[i][2:0]);
            end
        end
    end
    
    // 流水线第二级 - 比较中间3位
    always @(posedge clk) begin
        if (restart) begin
            data_stage2 <= 'b0;
            partial_matches_stage2 <= {DEPTH{1'b1}};
        end else if (valid_stage1) begin
            data_stage2 <= data_stage1;
            
            for (i = 0; i < DEPTH; i = i + 1) begin
                partial_matches_stage2[i] <= partial_matches_stage1[i] & 
                                            (data_stage1[5:3] == cam_entry[i][5:3]);
            end
        end
    end
    
    // 流水线第三级 - 比较高3位并产生最终结果
    always @(posedge clk) begin
        if (restart) begin
            data_stage3 <= 'b0;
            partial_matches <= {DEPTH{1'b0}};
        end else if (valid_stage2) begin
            data_stage3 <= data_stage2;
            
            for (i = 0; i < DEPTH; i = i + 1) begin
                partial_matches[i] <= partial_matches_stage2[i] & 
                                     (data_stage2[8:6] == cam_entry[i][8:6]);
            end
        end
    end
endmodule