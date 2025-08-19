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
    wire [LFSR_WIDTH-1:0] lfsr_value;
    wire [DATA_WIDTH-1:0] key_bits;
    
    // LFSR生成器子模块实例化
    lfsr_generator #(
        .WIDTH(LFSR_WIDTH)
    ) lfsr_gen_inst (
        .clk        (clk),
        .arst_l     (arst_l),
        .seed_load  (seed_load),
        .seed       (seed),
        .lfsr_out   (lfsr_value)
    );
    
    // 密钥提取子模块实例化
    key_extractor #(
        .LFSR_WIDTH (LFSR_WIDTH),
        .KEY_WIDTH  (DATA_WIDTH)
    ) key_ext_inst (
        .lfsr_value (lfsr_value),
        .key_bits   (key_bits)
    );
    
    // 数据加密子模块实例化
    data_processor #(
        .DATA_WIDTH (DATA_WIDTH)
    ) processor_inst (
        .clk        (clk),
        .arst_l     (arst_l),
        .encrypt    (encrypt),
        .key_bits   (key_bits),
        .data_i     (data_i),
        .data_o     (data_o)
    );
    
endmodule

// LFSR生成器子模块 - 负责生成伪随机序列
module lfsr_generator #(
    parameter WIDTH = 16
) (
    input  wire             clk,
    input  wire             arst_l,
    input  wire             seed_load,
    input  wire [WIDTH-1:0] seed,
    output wire [WIDTH-1:0] lfsr_out
);
    reg [WIDTH-1:0] lfsr_reg;
    wire feedback;
    
    // 使用反馈计算模块
    lfsr_feedback #(
        .WIDTH(WIDTH)
    ) feedback_inst (
        .lfsr_reg  (lfsr_reg),
        .feedback  (feedback)
    );
    
    // LFSR寄存器更新逻辑
    always @(posedge clk or negedge arst_l) begin
        if (~arst_l) 
            lfsr_reg <= {WIDTH{1'b1}};
        else if (seed_load) 
            lfsr_reg <= seed;
        else 
            lfsr_reg <= {feedback, lfsr_reg[WIDTH-1:1]};
    end
    
    // 输出赋值
    assign lfsr_out = lfsr_reg;
    
endmodule

// LFSR反馈计算模块 - 计算反馈值
module lfsr_feedback #(
    parameter WIDTH = 16
) (
    input  wire [WIDTH-1:0] lfsr_reg,
    output wire             feedback
);
    // 计算反馈值 - 使用特定的抽头位置
    // 可以根据不同应用要求修改抽头位置
    assign feedback = lfsr_reg[0] ^ lfsr_reg[2] ^ lfsr_reg[3] ^ lfsr_reg[5];
endmodule

// 密钥提取模块 - 从LFSR值中提取密钥位
module key_extractor #(
    parameter LFSR_WIDTH = 16,
    parameter KEY_WIDTH  = 8
) (
    input  wire [LFSR_WIDTH-1:0] lfsr_value,
    output wire [KEY_WIDTH-1:0]  key_bits
);
    // 提取用于加密的LFSR位
    assign key_bits = lfsr_value[LFSR_WIDTH-1:LFSR_WIDTH-KEY_WIDTH];
endmodule

// 数据处理模块 - 负责对数据进行加密/解密操作
module data_processor #(
    parameter DATA_WIDTH = 8
) (
    input  wire                  clk,
    input  wire                  arst_l,
    input  wire                  encrypt,
    input  wire [DATA_WIDTH-1:0] key_bits,
    input  wire [DATA_WIDTH-1:0] data_i,
    output reg  [DATA_WIDTH-1:0] data_o
);
    // 加密/解密逻辑
    always @(posedge clk or negedge arst_l) begin
        if (~arst_l) 
            data_o <= {DATA_WIDTH{1'b0}};
        else if (encrypt) 
            data_o <= data_i ^ key_bits;
        else
            data_o <= data_o; // 保持当前值
    end
endmodule