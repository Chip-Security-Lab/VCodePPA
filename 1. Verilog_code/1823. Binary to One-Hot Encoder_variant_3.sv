//SystemVerilog
module binary_to_onehot_sync #(parameter ADDR_WIDTH = 4) (
    input                       clk,
    input                       rst_n,
    input                       enable,
    input      [ADDR_WIDTH-1:0] binary_in,
    output reg [2**ADDR_WIDTH-1:0] onehot_out
);
    // 流水线阶段寄存器
    reg [ADDR_WIDTH-1:0] binary_stage1;
    reg [ADDR_WIDTH/2-1:0] binary_stage1_upper, binary_stage1_lower;
    reg [(2**(ADDR_WIDTH/2))-1:0] partial_decode_upper, partial_decode_lower;
    reg valid_stage1, valid_stage2;
    
    // 阶段1: 寄存输入并分割二进制数据为上下两部分
    always @(posedge clk) begin
        if (!rst_n) begin
            binary_stage1 <= {ADDR_WIDTH{1'b0}};
            binary_stage1_upper <= {(ADDR_WIDTH/2){1'b0}};
            binary_stage1_lower <= {(ADDR_WIDTH/2){1'b0}};
            valid_stage1 <= 1'b0;
        end
        else if (enable) begin
            binary_stage1 <= binary_in;
            binary_stage1_upper <= binary_in[ADDR_WIDTH-1:ADDR_WIDTH/2];
            binary_stage1_lower <= binary_in[ADDR_WIDTH/2-1:0];
            valid_stage1 <= 1'b1;
        end
        else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 阶段2: 部分解码，将上半部分和下半部分分别转为独热码
    always @(posedge clk) begin
        if (!rst_n) begin
            partial_decode_upper <= {(2**(ADDR_WIDTH/2)){1'b0}};
            partial_decode_lower <= {(2**(ADDR_WIDTH/2)){1'b0}};
            valid_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            partial_decode_upper <= 1'b1 << binary_stage1_upper;
            partial_decode_lower <= 1'b1 << binary_stage1_lower;
            valid_stage2 <= 1'b1;
        end
        else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 阶段3: 最终组合，将部分解码结果组合成完整的独热码
    always @(posedge clk) begin
        if (!rst_n)
            onehot_out <= {(2**ADDR_WIDTH){1'b0}};
        else if (valid_stage2) begin
            // 使用笛卡尔积组合上半部分和下半部分的独热码结果
            onehot_out <= {(2**ADDR_WIDTH){1'b0}};
            for (integer i = 0; i < 2**(ADDR_WIDTH/2); i = i + 1) begin
                for (integer j = 0; j < 2**(ADDR_WIDTH/2); j = j + 1) begin
                    if (partial_decode_upper[i] && partial_decode_lower[j])
                        onehot_out[i*(2**(ADDR_WIDTH/2))+j] <= 1'b1;
                end
            end
        end
    end
endmodule