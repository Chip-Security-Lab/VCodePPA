//SystemVerilog
module xor_stream_cipher #(parameter KEY_WIDTH = 8, DATA_WIDTH = 16) (
    input wire clk, rst_n,
    input wire [KEY_WIDTH-1:0] key,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire valid_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out,
    // 流水线控制信号
    input wire ready_in,
    output wire ready_out
);
    // 流水线寄存器定义
    reg [KEY_WIDTH-1:0] key_stage1, key_stage2, key_stage3;
    reg [KEY_WIDTH-1:0] shifted_key_stage1, shifted_key_stage2;
    reg [DATA_WIDTH-1:0] data_stage1, data_stage2, data_stage3;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 流水线控制逻辑
    assign ready_out = 1'b1; // 本设计始终准备好接收新数据
    wire pipeline_enable = ready_in || !valid_stage3;
    
    //=========== 第一级流水线模块 ===========//
    
    // 密钥寄存和初步处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_stage1 <= {KEY_WIDTH{1'b0}};
            shifted_key_stage1 <= {KEY_WIDTH{1'b0}};
        end else if (pipeline_enable) begin
            key_stage1 <= key;
            // 预计算移位密钥
            shifted_key_stage1 <= {key[0], key[KEY_WIDTH-1:1]};
        end
    end
    
    // 数据和有效信号寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {DATA_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (pipeline_enable) begin
            data_stage1 <= data_in;
            valid_stage1 <= valid_in;
        end
    end
    
    //=========== 第二级流水线模块 ===========//
    
    // 密钥信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_stage2 <= {KEY_WIDTH{1'b0}};
            shifted_key_stage2 <= {KEY_WIDTH{1'b0}};
        end else if (pipeline_enable) begin
            key_stage2 <= key_stage1;
            shifted_key_stage2 <= shifted_key_stage1;
        end
    end
    
    // 数据和有效信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {DATA_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (pipeline_enable) begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    //=========== 第三级流水线模块 ===========//
    
    // 密钥更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_stage3 <= {KEY_WIDTH{1'b0}};
        end else if (pipeline_enable) begin
            // 计算新密钥
            key_stage3 <= key_stage2 ^ shifted_key_stage2;
        end
    end
    
    // 加密数据处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3 <= {DATA_WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end else if (pipeline_enable) begin
            // XOR加密操作
            data_stage3 <= data_stage2 ^ {DATA_WIDTH/KEY_WIDTH{shifted_key_stage2}};
            valid_stage3 <= valid_stage2;
        end
    end
    
    //=========== 输出逻辑模块 ===========//
    
    // 数据输出控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DATA_WIDTH{1'b0}};
        end else if (pipeline_enable) begin
            data_out <= data_stage3;
        end
    end
    
    // 有效信号输出控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
        end else if (pipeline_enable) begin
            valid_out <= valid_stage3;
        end
    end
    
endmodule