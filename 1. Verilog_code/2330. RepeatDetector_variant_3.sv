//SystemVerilog
module RepeatDetector #(parameter WIN=8) (
    input clk, rst_n,
    input [7:0] data,
    output reg [15:0] code
);
    reg [7:0] history [0:WIN-1];
    reg [3:0] ptr;
    reg [3:0] next_ptr;
    integer i;

    // Brent-Kung adder signals
    wire [3:0] p_stage1[0:1];
    wire [3:0] g_stage1[0:1];
    wire [3:0] p_stage2;
    wire [3:0] g_stage2;
    wire [3:0] carry;
    wire [3:0] sum;
    
    // 重复数据检测信号
    wire is_repeat;
    wire [7:0] prev_data;

    // 初始化
    initial begin
        ptr = 0;
        for(i=0; i<WIN; i=i+1)
            history[i] = 0;
    end

    // Brent-Kung adder implementation - Stage 1: Generate propagate and generate signals
    assign p_stage1[0][0] = ptr[0] ^ 1'b1;
    assign g_stage1[0][0] = ptr[0] & 1'b1;
    assign p_stage1[0][1] = ptr[1] ^ 1'b0;
    assign g_stage1[0][1] = ptr[1] & 1'b0;
    assign p_stage1[0][2] = ptr[2] ^ 1'b0;
    assign g_stage1[0][2] = ptr[2] & 1'b0;
    assign p_stage1[0][3] = ptr[3] ^ 1'b0;
    assign g_stage1[0][3] = ptr[3] & 1'b0;

    // Stage 2: Group propagate and generate
    assign p_stage1[1][0] = p_stage1[0][0];
    assign g_stage1[1][0] = g_stage1[0][0];
    assign p_stage1[1][1] = p_stage1[0][0] & p_stage1[0][1];
    assign g_stage1[1][1] = g_stage1[0][1] | (p_stage1[0][1] & g_stage1[0][0]);
    assign p_stage1[1][2] = p_stage1[0][2];
    assign g_stage1[1][2] = g_stage1[0][2];
    assign p_stage1[1][3] = p_stage1[0][2] & p_stage1[0][3];
    assign g_stage1[1][3] = g_stage1[0][3] | (p_stage1[0][3] & g_stage1[0][2]);

    // Stage 3: Final group propagate and generate
    assign p_stage2[0] = p_stage1[1][0];
    assign g_stage2[0] = g_stage1[1][0];
    assign p_stage2[1] = p_stage1[1][1];
    assign g_stage2[1] = g_stage1[1][1];
    assign p_stage2[2] = p_stage1[1][1] & p_stage1[1][2];
    assign g_stage2[2] = g_stage1[1][2] | (p_stage1[1][2] & g_stage1[1][1]);
    assign p_stage2[3] = p_stage1[1][1] & p_stage1[1][3];
    assign g_stage2[3] = g_stage1[1][3] | (p_stage1[1][3] & g_stage1[1][1]);

    // Carry calculation
    assign carry[0] = g_stage2[0];
    assign carry[1] = g_stage2[1];
    assign carry[2] = g_stage2[2];
    assign carry[3] = g_stage2[3];

    // Sum calculation
    assign sum[0] = ptr[0] ^ 1'b1 ^ 1'b0;
    assign sum[1] = ptr[1] ^ 1'b0 ^ carry[0];
    assign sum[2] = ptr[2] ^ 1'b0 ^ carry[1];
    assign sum[3] = ptr[3] ^ 1'b0 ^ carry[2];

    // 确定前一个数据用于重复检测
    assign prev_data = (ptr > 0) ? history[ptr-1] : history[WIN-1];
    
    // 重复检测逻辑
    assign is_repeat = (data == prev_data);

    // 计算下一个指针值 - 组合逻辑
    always @(*) begin
        if (ptr == WIN-1)
            next_ptr = 0;
        else
            next_ptr = sum;
    end

    // 历史数据更新 - 时序逻辑
    always @(posedge clk) begin
        if(!rst_n) begin
            for(i=0; i<WIN; i=i+1)
                history[i] <= 0;
            ptr <= 0;
        end
        else begin
            history[ptr] <= data;
            ptr <= next_ptr;
        end
    end
    
    // 编码输出逻辑 - 时序逻辑
    always @(posedge clk) begin
        if(!rst_n) begin
            code <= 0;
        end
        else begin
            if(is_repeat)
                code <= {8'hFF, data};
            else
                code <= {8'h00, data};
        end
    end
endmodule