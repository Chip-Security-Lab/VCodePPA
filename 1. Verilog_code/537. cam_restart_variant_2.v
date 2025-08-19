module cam_restart #(parameter WIDTH=10, DEPTH=32)(
    input clk,
    input restart,
    input write_en,                      
    input [$clog2(DEPTH)-1:0] write_addr, 
    input [WIDTH-1:0] write_data,        
    input [WIDTH-1:0] data_in,
    output reg [DEPTH-1:0] partial_matches
);
    reg [2:0] compare_phase;
    reg [WIDTH-1:0] cam_entry [0:DEPTH-1];
    
    // 缓存高扇出信号data_in，并实现多级寄存流水线
    reg [WIDTH-1:0] data_in_buf1, data_in_buf2;
    wire [2:0] data_in_slice1 = data_in_buf1[2:0];
    wire [2:0] data_in_slice2 = data_in_buf1[5:3];
    wire [2:0] data_in_slice3 = data_in_buf1[8:6];
    
    // 为compare_phase添加缓冲流水线
    reg [2:0] compare_phase_buf1, compare_phase_buf2;
    
    // 缓存cam_entry数据
    reg [WIDTH-1:0] cam_entry_buf1 [0:DEPTH/2-1];
    reg [WIDTH-1:0] cam_entry_buf2 [0:DEPTH/2-1];
    
    // 分离部分匹配结果，减少扇出
    reg [DEPTH/2-1:0] partial_matches_low;
    reg [DEPTH/2-1:0] partial_matches_high;
    
    // 比较逻辑的中间结果流水线寄存器
    reg [DEPTH/2-1:0] compare_result_low, compare_result_high;
    
    // 分段比较的流水线寄存器
    reg [DEPTH/2-1:0] slice_match_low, slice_match_high;
    
    // 寄存data_in减少扇出影响并实现流水线
    always @(posedge clk) begin
        data_in_buf1 <= data_in;
        data_in_buf2 <= data_in_buf1;
        compare_phase_buf1 <= compare_phase;
        compare_phase_buf2 <= compare_phase_buf1;
    end
    
    // 缓存CAM条目减少扇出
    integer j;
    always @(posedge clk) begin
        for(j=0; j<DEPTH/2; j=j+1) begin
            cam_entry_buf1[j] <= cam_entry[j];
            cam_entry_buf2[j] <= cam_entry[DEPTH/2+j];
        end
    end
    
    // 写入逻辑
    always @(posedge clk) begin
        if (write_en)
            cam_entry[write_addr] <= write_data;
    end
    
    // 比较逻辑阶段1 - 计算当前片段的比较结果
    integer k;
    always @(posedge clk) begin
        for(k=0; k<DEPTH/2; k=k+1) begin
            case(compare_phase_buf1)
                3'd0: begin
                    slice_match_low[k] <= (data_in_slice1 == cam_entry_buf1[k][2:0]);
                    slice_match_high[k] <= (data_in_slice1 == cam_entry_buf2[k][2:0]);
                end
                3'd1: begin
                    slice_match_low[k] <= (data_in_slice2 == cam_entry_buf1[k][5:3]);
                    slice_match_high[k] <= (data_in_slice2 == cam_entry_buf2[k][5:3]);
                end
                3'd2: begin
                    slice_match_low[k] <= (data_in_slice3 == cam_entry_buf1[k][8:6]);
                    slice_match_high[k] <= (data_in_slice3 == cam_entry_buf2[k][8:6]);
                end
                default: begin
                    slice_match_low[k] <= 1'b1;
                    slice_match_high[k] <= 1'b1;
                end
            endcase
        end
    end
    
    // 比较逻辑阶段2 - 结合前一阶段结果
    integer i;
    always @(posedge clk) begin
        if(restart) begin
            compare_phase <= 0;
            partial_matches_low <= {(DEPTH/2){1'b1}};
            partial_matches_high <= {(DEPTH/2){1'b1}};
        end else begin
            compare_phase <= compare_phase + 1;
            
            // 处理低半部分，使用流水线比较结果
            for(i=0; i<DEPTH/2; i=i+1) begin
                partial_matches_low[i] <= partial_matches_low[i] & slice_match_low[i];
            end
            
            // 处理高半部分，使用流水线比较结果
            for(i=0; i<DEPTH/2; i=i+1) begin
                partial_matches_high[i] <= partial_matches_high[i] & slice_match_high[i];
            end
        end
    end
    
    // 分阶段合并匹配结果
    reg [DEPTH/2-1:0] partial_matches_high_buf, partial_matches_low_buf;
    
    always @(posedge clk) begin
        partial_matches_high_buf <= partial_matches_high;
        partial_matches_low_buf <= partial_matches_low;
        partial_matches <= {partial_matches_high_buf, partial_matches_low_buf};
    end
endmodule