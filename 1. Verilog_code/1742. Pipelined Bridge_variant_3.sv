//SystemVerilog
module pipeline_bridge #(parameter DWIDTH=32) (
    input clk, rst_n,
    input [DWIDTH-1:0] in_data,
    input in_valid,
    output reg in_ready,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid,
    input out_ready
);

    reg [DWIDTH-1:0] stage1_data, stage2_data;
    reg stage1_valid, stage2_valid;
    
    // 9位先行借位减法器相关信号
    wire [8:0] minuend, subtrahend;
    wire [8:0] difference;
    wire [8:0] borrow;
    
    // 从输入数据中提取9位操作数
    assign minuend = {1'b0, in_data[7:0]};
    assign subtrahend = {1'b0, in_data[15:8]};
    
    // 生成借位信号
    assign borrow[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : borrow_gen
            assign borrow[i+1] = (minuend[i] < subtrahend[i]) || 
                               ((minuend[i] == subtrahend[i]) && borrow[i]);
        end
    endgenerate
    
    // 计算差值
    assign difference = minuend - subtrahend - borrow;

    // 复位逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_valid <= 0;
            stage2_valid <= 0;
            out_valid <= 0;
            in_ready <= 1;
        end
    end

    // Stage 2到输出逻辑
    always @(posedge clk) begin
        if (rst_n) begin
            if (!out_valid || out_ready) begin
                out_data <= stage2_data;
                out_valid <= stage2_valid;
                stage2_valid <= 0;
            end
        end
    end

    // Stage 1到Stage 2逻辑
    always @(posedge clk) begin
        if (rst_n) begin
            if (!stage2_valid || !out_valid || out_ready) begin
                stage2_data <= {stage1_data[DWIDTH-1:16], stage1_data[15:8], difference[7:0]};
                stage2_valid <= stage1_valid;
                stage1_valid <= 0;
            end
        end
    end

    // 输入到Stage 1逻辑
    always @(posedge clk) begin
        if (rst_n) begin
            if (!stage1_valid || (!stage2_valid || !out_valid || out_ready)) begin
                if (in_valid && in_ready) begin
                    stage1_data <= in_data;
                    stage1_valid <= 1;
                end
                in_ready <= !stage1_valid || (!stage2_valid || !out_valid || out_ready);
            end
        end
    end

endmodule