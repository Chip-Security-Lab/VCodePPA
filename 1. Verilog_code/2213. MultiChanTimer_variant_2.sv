//SystemVerilog (IEEE 1364-2005)
module MultiChanTimer #(parameter CH=4, DW=8) (
    input clk, rst_n,
    input [CH-1:0] chan_en,
    output [CH-1:0] trig_out
);
    wire [CH-1:0] count_done;
    
    // 实例化CH个计时器通道子模块
    genvar i;
    generate
        for(i=0; i<CH; i=i+1) begin : timer_channels
            TimerChannel #(
                .DW(DW)
            ) timer_channel_inst (
                .clk(clk),
                .rst_n(rst_n),
                .chan_en(chan_en[i]),
                .count_done(count_done[i])
            );
        end
    endgenerate
    
    // 输出触发信号生成子模块
    TriggerGenerator #(
        .CH(CH)
    ) trigger_gen_inst (
        .count_done(count_done),
        .trig_out(trig_out)
    );
endmodule

//SystemVerilog (IEEE 1364-2005)
module TimerChannel #(parameter DW=8) (
    input clk,
    input rst_n,
    input chan_en,
    output count_done
);
    reg [DW-1:0] cnt;
    reg [DW-1:0] next_cnt;
    
    // 计数器的下一状态逻辑
    always @(*) begin
        case ({!rst_n || count_done, chan_en})
            2'b10, 2'b11: next_cnt = {DW{1'b0}}; // 复位或计数完成
            2'b01:        next_cnt = cnt + 1'b1; // 计数使能
            2'b00:        next_cnt = cnt;        // 保持当前值
        endcase
    end
    
    // 计数器寄存器更新
    always @(posedge clk) begin
        cnt <= next_cnt;
    end
    
    // 计数完成检测
    assign count_done = (cnt == {DW{1'b1}});
endmodule

//SystemVerilog (IEEE 1364-2005)
module TriggerGenerator #(parameter CH=4) (
    input [CH-1:0] count_done,
    output [CH-1:0] trig_out
);
    // 触发信号生成逻辑
    // 在此简单设计中，触发信号直接等于计数完成信号
    assign trig_out = count_done;
endmodule