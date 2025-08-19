//SystemVerilog
module parameterized_type_comp #(
    parameter WIDTH = 8,
    parameter DATA_WIDTH = 8
)(
    input clk, rst_n,
    input [DATA_WIDTH-1:0] inputs [0:WIDTH-1],
    output reg [$clog2(WIDTH)-1:0] max_idx,
    output reg valid
);

    // 使用组合逻辑进行并行比较
    wire [WIDTH-1:0] greater_flags;
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_comp
            assign greater_flags[i] = (inputs[i] > inputs[max_idx]);
        end
    endgenerate

    // 使用优先级编码器选择最大值索引
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max_idx <= 0;
            valid <= 0;
        end else begin
            valid <= 1;
            max_idx <= 0;
            
            for (integer j = WIDTH-1; j >= 0; j = j - 1) begin
                if (greater_flags[j]) begin
                    max_idx <= j[$clog2(WIDTH)-1:0];
                end
            end
        end
    end

endmodule