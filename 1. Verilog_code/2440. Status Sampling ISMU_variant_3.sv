//SystemVerilog
module status_sampling_ismu #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rstn,
    input wire [WIDTH-1:0] int_raw,
    input wire sample_en,
    output wire [WIDTH-1:0] int_status,
    output wire status_valid
);
    // 内部信号声明
    wire [WIDTH-1:0] int_raw_stage1, int_raw_stage2;
    wire sample_en_stage1, sample_en_stage2;
    wire valid_stage1, valid_stage2;
    wire [WIDTH-1:0] int_prev;

    // 第一级流水线子模块实例化
    input_capture_stage #(
        .WIDTH(WIDTH)
    ) input_stage (
        .clk(clk),
        .rstn(rstn),
        .int_raw(int_raw),
        .sample_en(sample_en),
        .int_raw_stage1(int_raw_stage1),
        .sample_en_stage1(sample_en_stage1),
        .valid_stage1(valid_stage1),
        .int_prev(int_prev)
    );

    // 第二级流水线子模块实例化
    processing_stage #(
        .WIDTH(WIDTH)
    ) process_stage (
        .clk(clk),
        .rstn(rstn),
        .int_raw_stage1(int_raw_stage1),
        .sample_en_stage1(sample_en_stage1),
        .valid_stage1(valid_stage1),
        .int_raw_stage2(int_raw_stage2),
        .sample_en_stage2(sample_en_stage2),
        .valid_stage2(valid_stage2)
    );

    // 第三级流水线子模块实例化
    output_generation_stage #(
        .WIDTH(WIDTH)
    ) output_stage (
        .clk(clk),
        .rstn(rstn),
        .int_raw_stage2(int_raw_stage2),
        .sample_en_stage2(sample_en_stage2),
        .valid_stage2(valid_stage2),
        .int_status(int_status),
        .status_valid(status_valid)
    );

endmodule

// 第一级流水线：捕获输入
module input_capture_stage #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rstn,
    input wire [WIDTH-1:0] int_raw,
    input wire sample_en,
    output reg [WIDTH-1:0] int_raw_stage1,
    output reg sample_en_stage1,
    output reg valid_stage1,
    output reg [WIDTH-1:0] int_prev
);
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            int_raw_stage1 <= {WIDTH{1'b0}};
            sample_en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            int_prev <= {WIDTH{1'b0}};
        end else begin
            int_raw_stage1 <= int_raw;
            sample_en_stage1 <= sample_en;
            valid_stage1 <= 1'b1;  // 指示第一级流水线有效
            int_prev <= int_raw;
        end
    end
    
endmodule

// 第二级流水线：处理采样逻辑
module processing_stage #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rstn,
    input wire [WIDTH-1:0] int_raw_stage1,
    input wire sample_en_stage1,
    input wire valid_stage1,
    output reg [WIDTH-1:0] int_raw_stage2,
    output reg sample_en_stage2,
    output reg valid_stage2
);
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            int_raw_stage2 <= {WIDTH{1'b0}};
            sample_en_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            int_raw_stage2 <= int_raw_stage1;
            sample_en_stage2 <= sample_en_stage1;
            valid_stage2 <= 1'b1;  // 传递有效信号
        end else begin
            valid_stage2 <= 1'b0;
        end
    end
    
endmodule

// 第三级流水线：产生输出
module output_generation_stage #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rstn,
    input wire [WIDTH-1:0] int_raw_stage2,
    input wire sample_en_stage2,
    input wire valid_stage2,
    output reg [WIDTH-1:0] int_status,
    output reg status_valid
);
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            int_status <= {WIDTH{1'b0}};
            status_valid <= 1'b0;
        end else if (valid_stage2) begin
            if (sample_en_stage2) begin
                int_status <= int_raw_stage2;
                status_valid <= 1'b1;
            end else begin
                status_valid <= 1'b0;
            end
        end else begin
            status_valid <= 1'b0;
        end
    end
    
endmodule