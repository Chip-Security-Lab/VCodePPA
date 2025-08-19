//SystemVerilog
module MultiChanTimer #(parameter CH=4, DW=8) (
    input clk, rst_n,
    input [CH-1:0] chan_en,
    output reg [CH-1:0] trig_out
);
    // 定义流水线寄存器
    reg [DW-1:0] cnt_stage1[0:CH-1];
    reg [DW-1:0] cnt_stage2[0:CH-1];
    reg [CH-1:0] chan_en_stage1;
    reg [CH-1:0] chan_en_stage2;
    reg [CH-1:0] max_val_stage1;
    reg [CH-1:0] max_val_stage2;
    reg [CH-1:0] trig_stage1;
    reg [CH-1:0] trig_stage2;
    
    // 流水线控制信号
    reg [CH-1:0] valid_stage1;
    reg [CH-1:0] valid_stage2;
    
    // 条件求和减法算法的信号
    wire [DW-1:0] max_value;
    wire [DW-1:0] next_cnt [0:CH-1];
    wire [DW-1:0] cond_sub_result [0:CH-1];
    wire [DW:0] borrow [0:CH-1];
    
    // 最大值为 2^DW - 1
    assign max_value = {DW{1'b1}};
    
    genvar i;
    generate 
        for(i=0; i<CH; i=i+1) begin : ch_gen
            // 条件求和减法器实现
            // 检查计数器是否达到最大值，使用条件求和减法算法
            assign borrow[i][0] = 1'b0;
            
            genvar j;
            for(j=0; j<DW; j=j+1) begin : cond_sub_bit
                assign cond_sub_result[i][j] = cnt_stage1[i][j] ^ max_value[j] ^ borrow[i][j];
                assign borrow[i][j+1] = (cnt_stage1[i][j] & max_value[j]) | 
                                       (cnt_stage1[i][j] & borrow[i][j]) | 
                                       (max_value[j] & borrow[i][j]);
            end
            
            // 如果borrow[DW]=0，则说明cnt_stage1 == max_value
            assign next_cnt[i] = chan_en[i] ? 
                                 (trig_out[i] ? {DW{1'b0}} : cnt_stage1[i] + 1'b1) :
                                 cnt_stage1[i];
            
            // 第一级流水线 - 寄存输入并检测最大值
            always @(posedge clk) begin
                if(!rst_n) begin
                    cnt_stage1[i] <= 0;
                    chan_en_stage1[i] <= 0;
                    max_val_stage1[i] <= 0;
                    valid_stage1[i] <= 0;
                end else begin
                    chan_en_stage1[i] <= chan_en[i];
                    valid_stage1[i] <= 1'b1;
                    max_val_stage1[i] <= ~borrow[i][DW]; // 使用条件求和减法的结果
                    
                    if(trig_out[i]) begin
                        cnt_stage1[i] <= 0;
                    end else if(chan_en[i]) begin
                        cnt_stage1[i] <= cnt_stage1[i] + 1'b1;
                    end
                end
            end
            
            // 第二级流水线 - 计算触发条件
            always @(posedge clk) begin
                if(!rst_n) begin
                    cnt_stage2[i] <= 0;
                    chan_en_stage2[i] <= 0;
                    max_val_stage2[i] <= 0;
                    valid_stage2[i] <= 0;
                    trig_stage1[i] <= 0;
                end else begin
                    cnt_stage2[i] <= cnt_stage1[i];
                    chan_en_stage2[i] <= chan_en_stage1[i];
                    max_val_stage2[i] <= max_val_stage1[i];
                    valid_stage2[i] <= valid_stage1[i];
                    
                    // 检测计数器是否达到最大值
                    if(valid_stage1[i] && max_val_stage1[i]) begin
                        trig_stage1[i] <= 1'b1;
                    end else begin
                        trig_stage1[i] <= 1'b0;
                    end
                end
            end
            
            // 第三级流水线 - 输出触发信号
            always @(posedge clk) begin
                if(!rst_n) begin
                    trig_stage2[i] <= 0;
                    trig_out[i] <= 0;
                end else begin
                    trig_stage2[i] <= trig_stage1[i];
                    
                    // 输出触发信号
                    if(valid_stage2[i]) begin
                        trig_out[i] <= trig_stage2[i];
                    end else begin
                        trig_out[i] <= 0;
                    end
                end
            end
        end
    endgenerate
endmodule