//SystemVerilog
// 顶层模块
module lfsr_stream_cipher #(
    parameter LFSR_WIDTH = 16,
    parameter DATA_WIDTH = 8
) (
    input  wire                    clk,
    input  wire                    arst_l,
    input  wire                    seed_load,
    input  wire                    encrypt,
    input  wire [LFSR_WIDTH-1:0]   seed,
    input  wire [DATA_WIDTH-1:0]   data_i,
    output wire [DATA_WIDTH-1:0]   data_o
);
    // 内部连线
    wire [LFSR_WIDTH-1:0]  lfsr_state;
    wire [DATA_WIDTH-1:0]  key_stream;
    
    // 数据加密逻辑预计算，减少加密处理器中的组合逻辑延迟
    wire [DATA_WIDTH-1:0]  encrypted_data = data_i ^ key_stream;

    // LFSR子模块实例化
    lfsr_generator #(
        .LFSR_WIDTH(LFSR_WIDTH)
    ) lfsr_gen_inst (
        .clk       (clk),
        .arst_l    (arst_l),
        .seed_load (seed_load),
        .seed      (seed),
        .lfsr_out  (lfsr_state)
    );

    // 密钥生成子模块实例化
    keystream_generator #(
        .LFSR_WIDTH(LFSR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) key_gen_inst (
        .lfsr_state  (lfsr_state),
        .key_stream  (key_stream)
    );

    // 加密处理子模块实例化
    encrypt_processor #(
        .DATA_WIDTH(DATA_WIDTH)
    ) encrypt_proc_inst (
        .clk           (clk),
        .arst_l        (arst_l),
        .encrypt       (encrypt),
        .encrypted_data(encrypted_data),
        .data_o        (data_o)
    );
endmodule

// LFSR生成器子模块
module lfsr_generator #(
    parameter LFSR_WIDTH = 16
) (
    input  wire                   clk,
    input  wire                   arst_l,
    input  wire                   seed_load,
    input  wire [LFSR_WIDTH-1:0]  seed,
    output reg  [LFSR_WIDTH-1:0]  lfsr_out
);
    // 预计算反馈位，分散反馈计算并利用寄存器减少组合逻辑深度
    reg [3:0] feedback_taps;
    wire feedback = ^feedback_taps;
    
    always @(*) begin
        feedback_taps[0] = lfsr_out[0];
        feedback_taps[1] = lfsr_out[2];
        feedback_taps[2] = lfsr_out[3];
        feedback_taps[3] = lfsr_out[5];
    end
    
    // LFSR状态更新逻辑
    always @(posedge clk or negedge arst_l) begin
        if (~arst_l) 
            lfsr_out <= {LFSR_WIDTH{1'b1}};
        else if (seed_load) 
            lfsr_out <= seed;
        else 
            lfsr_out <= {feedback, lfsr_out[LFSR_WIDTH-1:1]};
    end
endmodule

// 密钥流生成器子模块
module keystream_generator #(
    parameter LFSR_WIDTH = 16,
    parameter DATA_WIDTH = 8
) (
    input  wire [LFSR_WIDTH-1:0]  lfsr_state,
    output wire [DATA_WIDTH-1:0]  key_stream
);
    // 直接提取密钥流，无需修改
    assign key_stream = lfsr_state[LFSR_WIDTH-1:LFSR_WIDTH-DATA_WIDTH];
endmodule

// 加密处理器子模块 - 优化版本
module encrypt_processor #(
    parameter DATA_WIDTH = 8
) (
    input  wire                   clk,
    input  wire                   arst_l,
    input  wire                   encrypt,
    input  wire [DATA_WIDTH-1:0]  encrypted_data,
    output reg  [DATA_WIDTH-1:0]  data_o
);
    // 简化的加密逻辑，XOR操作已在顶层模块提前计算
    always @(posedge clk or negedge arst_l) begin
        if (~arst_l) 
            data_o <= {DATA_WIDTH{1'b0}};
        else if (encrypt) 
            data_o <= encrypted_data;
    end
endmodule