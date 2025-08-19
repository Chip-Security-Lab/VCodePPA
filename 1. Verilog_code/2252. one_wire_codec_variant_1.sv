//SystemVerilog
module one_wire_codec (
    input clk, rst,
    inout dq,
    output reg [7:0] romcode
);
    reg [2:0] state;
    reg precharge;
    
    // 添加dq缓冲寄存器
    reg dq_buf1, dq_buf2;
    
    // 添加romcode缓冲寄存器
    reg [7:0] romcode_buf;
    
    // 分段状态机，改善关键路径
    reg [2:0] next_state;
    
    // dq信号缓冲 - 拆分为独立always块
    always @(posedge clk) begin
        dq_buf1 <= dq;
    end
    
    always @(posedge clk) begin
        dq_buf2 <= dq_buf1;
    end
    
    // 状态转移逻辑 - 拆分为多个独立case判断
    always @(*) begin
        next_state = state;
        
        if (state == 3'd0 && !dq_buf2)
            next_state = 3'd1;
        else if (state == 3'd1 && dq_buf2)
            next_state = 3'd2;
        else if (state == 3'd2)
            next_state = 3'd3;
        else if (state == 3'd3)
            next_state = 3'd4;
        else if (state == 3'd4)
            next_state = 3'd5;
        else if (state == 3'd5)
            next_state = 3'd6;
        else if (state == 3'd6)
            next_state = 3'd7;
        else if (state == 3'd7)
            next_state = 3'd0;
    end
    
    // 状态寄存器更新
    always @(negedge clk) begin
        if (rst) begin
            state <= 3'd0;
        end else begin
            state <= next_state;
        end
    end
    
    // 预充电控制逻辑 - 单独拆分
    always @(negedge clk) begin
        if (rst) begin
            precharge <= 1'b0;
        end else if (state == 3'd0 && !dq_buf2) begin
            precharge <= 1'b1;
        end else if (state == 3'd1) begin
            precharge <= 1'b0;
        end
    end
    
    // romcode_buf初始化逻辑 - 单独拆分
    always @(negedge clk) begin
        if (rst) begin
            romcode_buf <= 8'd0;
        end else if (state == 3'd1 && dq_buf2) begin
            romcode_buf <= 8'd0;
        end
    end
    
    // romcode_buf位0更新逻辑
    always @(negedge clk) begin
        if (state == 3'd2)
            romcode_buf[0] <= dq_buf2;
    end
    
    // romcode_buf位1更新逻辑
    always @(negedge clk) begin
        if (state == 3'd3)
            romcode_buf[1] <= dq_buf2;
    end
    
    // romcode_buf位2更新逻辑
    always @(negedge clk) begin
        if (state == 3'd4)
            romcode_buf[2] <= dq_buf2;
    end
    
    // romcode_buf位3更新逻辑
    always @(negedge clk) begin
        if (state == 3'd5)
            romcode_buf[3] <= dq_buf2;
    end
    
    // romcode_buf位4更新逻辑
    always @(negedge clk) begin
        if (state == 3'd6)
            romcode_buf[4] <= dq_buf2;
    end
    
    // romcode_buf位5更新逻辑
    always @(negedge clk) begin
        if (state == 3'd7)
            romcode_buf[5] <= dq_buf2;
    end
    
    // 输出缓冲级
    always @(posedge clk) begin
        if (rst) begin
            romcode <= 8'd0;
        end else begin
            romcode <= romcode_buf;
        end
    end
    
    // 三态输出缓冲
    reg precharge_buf;
    always @(posedge clk) begin
        precharge_buf <= precharge;
    end
    
    // 三态输出赋值
    assign dq = precharge_buf ? 1'b0 : 1'bz;
endmodule