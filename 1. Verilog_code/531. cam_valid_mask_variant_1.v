// 顶层模块：CAM带有有效掩码功能
module cam_valid_mask #(
    parameter WIDTH = 12,
    parameter DEPTH = 64
)(
    input wire clk,
    input wire write_en,
    input wire [$clog2(DEPTH)-1:0] write_addr,
    input wire [WIDTH-1:0] write_data,
    input wire [WIDTH-1:0] data_in,
    input wire [DEPTH-1:0] valid_mask,
    output wire [DEPTH-1:0] match_lines
);
    // 内部信号
    wire [WIDTH-1:0] data_in_pipe;
    wire [DEPTH-1:0] valid_mask_pipe;
    wire [DEPTH-1:0] raw_matches;
    
    // 优化的输入流水管理模块
    input_stage #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) u_input_stage (
        .clk(clk),
        .data_in(data_in),
        .valid_mask(valid_mask),
        .data_out(data_in_pipe),
        .valid_mask_out(valid_mask_pipe)
    );
    
    // 优化的CAM核心逻辑模块
    cam_core #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) u_cam_core (
        .clk(clk),
        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),
        .compare_data(data_in_pipe),
        .match_results(raw_matches)
    );
    
    // 优化的匹配结果处理模块
    match_processor #(
        .DEPTH(DEPTH)
    ) u_match_processor (
        .clk(clk),
        .raw_matches(raw_matches),
        .valid_mask(valid_mask_pipe),
        .filtered_matches(match_lines)
    );
endmodule

// 输入阶段模块 - 负责输入数据与掩码的寄存与可能的预处理
module input_stage #(
    parameter WIDTH = 12,
    parameter DEPTH = 64
)(
    input wire clk,
    input wire [WIDTH-1:0] data_in,
    input wire [DEPTH-1:0] valid_mask,
    output reg [WIDTH-1:0] data_out,
    output reg [DEPTH-1:0] valid_mask_out
);
    // 优化的流水线寄存器 - 使用单一时钟域
    always @(posedge clk) begin
        data_out <= data_in;
        valid_mask_out <= valid_mask;
    end
endmodule

// CAM核心模块 - 专注于存储和比较功能
module cam_core #(
    parameter WIDTH = 12,
    parameter DEPTH = 64
)(
    input wire clk,
    input wire write_en,
    input wire [$clog2(DEPTH)-1:0] write_addr,
    input wire [WIDTH-1:0] write_data,
    input wire [WIDTH-1:0] compare_data,
    output reg [DEPTH-1:0] match_results
);
    // CAM存储单元
    reg [WIDTH-1:0] cam_mem [0:DEPTH-1];
    
    // 写入逻辑优化 - 单周期写入
    always @(posedge clk) begin
        if (write_en)
            cam_mem[write_addr] <= write_data;
    end
    
    // 比较逻辑优化 - 使用生成循环代替always中的循环提高性能
    genvar i;
    generate
        for (i = 0; i < DEPTH; i = i + 1) begin : compare_blocks
            always @(posedge clk) begin
                match_results[i] <= (cam_mem[i] == compare_data);
            end
        end
    endgenerate
endmodule

// 匹配处理模块 - 负责掩码应用及可能的后处理
module match_processor #(
    parameter DEPTH = 64
)(
    input wire clk,
    input wire [DEPTH-1:0] raw_matches,
    input wire [DEPTH-1:0] valid_mask,
    output reg [DEPTH-1:0] filtered_matches
);
    // 掩码应用逻辑优化 - 使用位操作提高效率
    always @(posedge clk) begin
        filtered_matches <= raw_matches & valid_mask;
    end
endmodule