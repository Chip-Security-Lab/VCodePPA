//SystemVerilog
module gen_ring_counter #(parameter WIDTH=8) (
    input wire clk,
    input wire rst,
    input wire valid_in,  // 输入有效信号
    output wire valid_out, // 输出有效信号
    output wire [WIDTH-1:0] cnt
);

    // 优化后的流水线结构
    reg [WIDTH-1:0] cnt_pipeline [2:0];
    reg [2:0] valid_pipeline;
    
    // 第一级流水线 - 初始化或移位操作
    always @(posedge clk) begin
        if (rst) begin
            cnt_pipeline[0] <= {{WIDTH-1{1'b0}}, 1'b1};
            valid_pipeline[0] <= 1'b0;
        end
        else begin
            if (valid_in) begin
                cnt_pipeline[0] <= {cnt[0], cnt[WIDTH-1:1]};
                valid_pipeline[0] <= 1'b1;
            end
            else begin
                valid_pipeline[0] <= 1'b0;
            end
        end
    end
    
    // 第二级和第三级流水线 - 整合处理
    genvar i;
    generate
        for (i = 1; i < 3; i = i + 1) begin : pipeline_stages
            always @(posedge clk) begin
                if (rst) begin
                    cnt_pipeline[i] <= {WIDTH{1'b0}};
                    valid_pipeline[i] <= 1'b0;
                end
                else begin
                    cnt_pipeline[i] <= cnt_pipeline[i-1];
                    valid_pipeline[i] <= valid_pipeline[i-1];
                end
            end
        end
    endgenerate
    
    // 输出赋值
    assign cnt = cnt_pipeline[2];
    assign valid_out = valid_pipeline[2];
    
endmodule