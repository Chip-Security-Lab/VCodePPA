//SystemVerilog
// IEEE 1364-2005 Verilog
module DynamicWidthShift #(parameter MAX_WIDTH=16) (
    input clk, rstn,
    input [$clog2(MAX_WIDTH)-1:0] width_sel,
    input din,
    output reg [MAX_WIDTH-1:0] q
);

// 添加时钟缓冲树
(* dont_touch = "true" *) reg clk_buf1, clk_buf2, clk_buf3;

always @(*) begin
    clk_buf1 = clk;
    clk_buf2 = clk_buf1;
    clk_buf3 = clk_buf1;
end

// 分段处理的区域定义
localparam SEGMENT_SIZE = MAX_WIDTH / 3;
localparam SEG1_END = SEGMENT_SIZE - 1;
localparam SEG2_END = 2 * SEGMENT_SIZE - 1;

// 为高扇出信号stage_din添加缓冲
reg [MAX_WIDTH-1:0] stage_din;
reg [SEGMENT_SIZE-1:0] stage_din_buf1, stage_din_buf2;

// 将connections分组缓冲以减少扇出
reg [MAX_WIDTH-1:0] connections;
reg [SEG1_END:0] connections_buf1;
reg [SEG2_END:SEG1_END+1] connections_buf2;
reg [MAX_WIDTH-1:SEG2_END+1] connections_buf3;

// 为q信号添加缓冲区
reg [SEG1_END:0] q_buf1;
reg [SEG2_END:SEG1_END+1] q_buf2;
reg [MAX_WIDTH-1:SEG2_END+1] q_buf3;

integer i;

// 寄存输入信号din
always @(posedge clk_buf1 or negedge rstn) begin
    if (!rstn) begin
        stage_din[0] <= 1'b0;
    end else begin
        stage_din[0] <= din;
    end
end

// 分组缓存stage_din信号，减少扇出负载
always @(posedge clk_buf1 or negedge rstn) begin
    if (!rstn) begin
        stage_din_buf1 <= 0;
        stage_din_buf2 <= 0;
    end else begin
        stage_din_buf1[0] <= stage_din[0];
        stage_din_buf2[0] <= stage_din[0];
    end
end

// 存储各级连接关系，分组处理减少扇出
always @(posedge clk_buf2 or negedge rstn) begin
    if (!rstn) begin
        connections_buf1 <= 0;
    end else begin
        for (i=0; i<=SEG1_END; i=i+1) begin
            if (i < MAX_WIDTH-1)
                connections_buf1[i] <= q[i];
        end
    end
end

always @(posedge clk_buf2 or negedge rstn) begin
    if (!rstn) begin
        connections_buf2 <= 0;
    end else begin
        for (i=SEG1_END+1; i<=SEG2_END; i=i+1) begin
            if (i < MAX_WIDTH-1)
                connections_buf2[i] <= q[i];
        end
    end
end

always @(posedge clk_buf2 or negedge rstn) begin
    if (!rstn) begin
        connections_buf3 <= 0;
    end else begin
        for (i=SEG2_END+1; i<MAX_WIDTH-1; i=i+1) begin
            connections_buf3[i] <= q[i];
        end
    end
end

// 合并连接信号
always @(posedge clk_buf1 or negedge rstn) begin
    if (!rstn) begin
        connections <= 0;
    end else begin
        for (i=0; i<=SEG1_END; i=i+1) begin
            if (i < MAX_WIDTH-1)
                connections[i] <= connections_buf1[i];
        end
        
        for (i=SEG1_END+1; i<=SEG2_END; i=i+1) begin
            if (i < MAX_WIDTH-1)
                connections[i] <= connections_buf2[i];
        end
        
        for (i=SEG2_END+1; i<MAX_WIDTH-1; i=i+1) begin
            connections[i] <= connections_buf3[i];
        end
    end
end

// 缓冲q信号
always @(posedge clk_buf3 or negedge rstn) begin
    if (!rstn) begin
        q_buf1 <= 0;
        q_buf2 <= 0;
        q_buf3 <= 0;
    end else begin
        // 第一段缓冲
        for (i=0; i<=SEG1_END; i=i+1) begin
            q_buf1[i] <= q[i];
        end
        
        // 第二段缓冲
        for (i=SEG1_END+1; i<=SEG2_END; i=i+1) begin
            q_buf2[i] <= q[i];
        end
        
        // 第三段缓冲
        for (i=SEG2_END+1; i<MAX_WIDTH; i=i+1) begin
            q_buf3[i] <= q[i];
        end
    end
end

// 输出逻辑，使用缓冲信号，并分段处理减少关键路径长度
always @(posedge clk_buf3 or negedge rstn) begin
    if (!rstn) begin
        q <= 0;
    end else begin
        // 第一位直接使用stage_din的缓冲
        q[0] <= stage_din_buf1[0];
        
        // 第一段使用connections_buf1
        for (i=1; i<=SEG1_END; i=i+1) begin
            if (i < width_sel)
                q[i] <= connections_buf1[i-1];
            else
                q[i] <= q_buf1[i];
        end
        
        // 第二段使用connections_buf2
        for (i=SEG1_END+1; i<=SEG2_END; i=i+1) begin
            if (i < width_sel)
                q[i] <= connections_buf2[i-1];
            else
                q[i] <= q_buf2[i];
        end
        
        // 第三段使用connections_buf3
        for (i=SEG2_END+1; i<MAX_WIDTH; i=i+1) begin
            if (i < width_sel)
                q[i] <= connections_buf3[i-1];
            else
                q[i] <= q_buf3[i];
        end
    end
end

endmodule