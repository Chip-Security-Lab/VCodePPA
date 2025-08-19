//SystemVerilog
module MultiChanTimer #(parameter CH=4, DW=8) (
    input wire clk,
    input wire rst_n,
    input wire [CH-1:0] chan_en,
    output wire [CH-1:0] trig_out
);
    // 内部连接信号
    wire [CH-1:0] trig_det_stage1;
    wire [CH-1:0] chan_en_stage1;
    wire [DW-1:0] cnt_stage1[0:CH-1];

    // 实例化计数器阶段模块
    CounterStage #(
        .CH(CH),
        .DW(DW)
    ) counter_stage (
        .clk(clk),
        .rst_n(rst_n),
        .chan_en(chan_en),
        .trig_out_reg(trig_out),
        .cnt_stage1(cnt_stage1),
        .trig_det_stage1(trig_det_stage1),
        .chan_en_stage1(chan_en_stage1)
    );

    // 实例化输出阶段模块
    OutputStage #(
        .CH(CH),
        .DW(DW)
    ) output_stage (
        .clk(clk),
        .rst_n(rst_n),
        .chan_en_stage1(chan_en_stage1),
        .cnt_stage1(cnt_stage1),
        .trig_det_stage1(trig_det_stage1),
        .trig_out(trig_out)
    );
    
endmodule

//===========================================================================
// 计数器模块：处理第一阶段流水线，负责计数和比较逻辑
//===========================================================================
module CounterStage #(parameter CH=4, DW=8) (
    input wire clk,
    input wire rst_n,
    input wire [CH-1:0] chan_en,
    input wire [CH-1:0] trig_out_reg,
    output reg [DW-1:0] cnt_stage1[0:CH-1],
    output reg [CH-1:0] trig_det_stage1,
    output reg [CH-1:0] chan_en_stage1
);
    // 第一阶段流水线 - 计数和检测触发
    integer j;
    always @(posedge clk) begin
        if (!rst_n) begin
            for (j=0; j<CH; j=j+1) begin
                cnt_stage1[j] <= {DW{1'b0}};
                trig_det_stage1[j] <= 1'b0;
            end
            chan_en_stage1 <= {CH{1'b0}};
        end else begin
            chan_en_stage1 <= chan_en;
            for (j=0; j<CH; j=j+1) begin
                // 检测每个通道是否达到最大计数值
                trig_det_stage1[j] <= (cnt_stage1[j] == {DW{1'b1}});
                
                // 根据触发状态和使能决定计数行为
                if (trig_out_reg[j]) begin
                    cnt_stage1[j] <= {DW{1'b0}};
                end else if (chan_en[j]) begin
                    cnt_stage1[j] <= cnt_stage1[j] + 1'b1;
                end
            end
        end
    end
endmodule

//===========================================================================
// 输出阶段模块：处理第二阶段流水线，负责更新计数和生成触发输出
//===========================================================================
module OutputStage #(parameter CH=4, DW=8) (
    input wire clk,
    input wire rst_n,
    input wire [CH-1:0] chan_en_stage1,
    input wire [DW-1:0] cnt_stage1[0:CH-1],
    input wire [CH-1:0] trig_det_stage1,
    output wire [CH-1:0] trig_out
);
    // 内部寄存器
    reg [DW-1:0] cnt_stage2[0:CH-1];
    reg [CH-1:0] chan_en_stage2;
    reg [CH-1:0] trig_out_reg;
    
    // 第二阶段流水线 - 触发输出
    integer j;
    always @(posedge clk) begin
        if (!rst_n) begin
            for (j=0; j<CH; j=j+1) begin
                cnt_stage2[j] <= {DW{1'b0}};
            end
            chan_en_stage2 <= {CH{1'b0}};
            trig_out_reg <= {CH{1'b0}};
        end else begin
            chan_en_stage2 <= chan_en_stage1;
            for (j=0; j<CH; j=j+1) begin
                cnt_stage2[j] <= cnt_stage1[j];
            end
            trig_out_reg <= trig_det_stage1;
        end
    end
    
    // 输出赋值
    assign trig_out = trig_out_reg;
    
endmodule