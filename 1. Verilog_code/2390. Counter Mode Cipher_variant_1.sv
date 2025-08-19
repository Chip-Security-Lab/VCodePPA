//SystemVerilog
module counter_mode_cipher #(parameter CTR_WIDTH = 16, DATA_WIDTH = 32) (
    input wire clk, reset,
    input wire enable, encrypt,
    input wire [CTR_WIDTH-1:0] init_ctr,
    input wire [DATA_WIDTH-1:0] data_in, key,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg data_valid
);
    // 流水线阶段寄存器
    reg [CTR_WIDTH-1:0] counter;
    
    // 阶段1: 计数器准备和加密
    reg [DATA_WIDTH-1:0] data_in_stage1;
    reg enable_stage1;
    reg [CTR_WIDTH-1:0] counter_stage1;
    reg [DATA_WIDTH-1:0] key_stage1;
    reg valid_stage1;
    
    // 阶段2: 计数器加密
    reg [DATA_WIDTH-1:0] data_in_stage2;
    reg [DATA_WIDTH-1:0] encrypted_ctr_stage2;
    reg valid_stage2;
    
    // 阶段1: 输入寄存和计数器更新
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_in_stage1 <= {DATA_WIDTH{1'b0}};
            enable_stage1 <= 1'b0;
            counter_stage1 <= init_ctr;
            key_stage1 <= {DATA_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
            counter <= init_ctr;
        end else begin
            data_in_stage1 <= data_in;
            enable_stage1 <= enable;
            key_stage1 <= key;
            valid_stage1 <= enable;
            
            if (enable) begin
                counter <= counter + 1'b1;
                counter_stage1 <= counter;
            end
        end
    end
    
    // 阶段2: 计数器加密
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_in_stage2 <= {DATA_WIDTH{1'b0}};
            encrypted_ctr_stage2 <= {DATA_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            data_in_stage2 <= data_in_stage1;
            encrypted_ctr_stage2 <= {counter_stage1, counter_stage1} ^ key_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 阶段3: 输出数据生成
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out <= {DATA_WIDTH{1'b0}};
            data_valid <= 1'b0;
        end else begin
            data_out <= data_in_stage2 ^ encrypted_ctr_stage2;
            data_valid <= valid_stage2;
        end
    end
endmodule