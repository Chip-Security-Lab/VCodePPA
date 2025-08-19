//SystemVerilog
module tagged_buffer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] data_in,
    input  wire [3:0]  tag_in,
    input  wire        write_en,
    input  wire        pipeline_ready,
    output wire        pipeline_valid,
    output wire [15:0] data_out,
    output wire [3:0]  tag_out
);
    // 内部连接信号
    wire [15:0] data_stage1, data_stage2;
    wire [3:0]  tag_stage1, tag_stage2;
    wire        valid_stage1, valid_stage2;
    
    // 共享的控制信号
    wire pipeline_advance = pipeline_ready;
    
    // 子模块实例化
    input_stage u_input_stage (
        .clk             (clk),
        .rst_n           (rst_n),
        .data_in         (data_in),
        .tag_in          (tag_in),
        .write_en        (write_en),
        .pipeline_advance(pipeline_advance),
        .data_out        (data_stage1),
        .tag_out         (tag_stage1),
        .valid_out       (valid_stage1)
    );
    
    processing_stage u_processing_stage (
        .clk             (clk),
        .rst_n           (rst_n),
        .data_in         (data_stage1),
        .tag_in          (tag_stage1),
        .valid_in        (valid_stage1),
        .pipeline_advance(pipeline_advance),
        .data_out        (data_stage2),
        .tag_out         (tag_stage2),
        .valid_out       (valid_stage2)
    );
    
    output_stage u_output_stage (
        .clk             (clk),
        .rst_n           (rst_n),
        .data_in         (data_stage2),
        .tag_in          (tag_stage2),
        .valid_in        (valid_stage2),
        .pipeline_advance(pipeline_advance),
        .data_out        (data_out),
        .tag_out         (tag_out),
        .pipeline_valid  (pipeline_valid)
    );
    
endmodule

// 输入处理子模块
module input_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] data_in,
    input  wire [3:0]  tag_in,
    input  wire        write_en,
    input  wire        pipeline_advance,
    output reg  [15:0] data_out,
    output reg  [3:0]  tag_out,
    output reg         valid_out
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= 16'b0;
            tag_out   <= 4'b0;
            valid_out <= 1'b0;
        end else if (pipeline_advance) begin
            data_out  <= write_en ? data_in : 16'b0;
            tag_out   <= write_en ? tag_in  : 4'b0;
            valid_out <= write_en;
        end
    end
    
endmodule

// 处理阶段子模块
module processing_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] data_in,
    input  wire [3:0]  tag_in,
    input  wire        valid_in,
    input  wire        pipeline_advance,
    output reg  [15:0] data_out,
    output reg  [3:0]  tag_out,
    output reg         valid_out
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= 16'b0;
            tag_out   <= 4'b0;
            valid_out <= 1'b0;
        end else if (pipeline_advance) begin
            data_out  <= data_in;
            tag_out   <= tag_in;
            valid_out <= valid_in;
        end
    end
    
endmodule

// 输出阶段子模块
module output_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] data_in,
    input  wire [3:0]  tag_in,
    input  wire        valid_in,
    input  wire        pipeline_advance,
    output reg  [15:0] data_out,
    output reg  [3:0]  tag_out,
    output reg         pipeline_valid
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out       <= 16'b0;
            tag_out        <= 4'b0;
            pipeline_valid <= 1'b0;
        end else if (pipeline_advance) begin
            data_out       <= data_in;
            tag_out        <= tag_in;
            pipeline_valid <= valid_in;
        end
    end
    
endmodule