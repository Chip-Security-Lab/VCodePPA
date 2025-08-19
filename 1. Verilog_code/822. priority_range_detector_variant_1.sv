//SystemVerilog
module priority_range_detector(
    input wire clk, rst_n,
    input wire [15:0] value,
    input wire [15:0] range_start [0:3],
    input wire [15:0] range_end [0:3],
    output reg [2:0] range_id,
    output reg valid
);

    // 优化后的比较逻辑
    wire [3:0] range_match;
    wire [2:0] next_range_id;
    wire next_valid;
    
    // 并行比较器实现
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_range_match
            assign range_match[i] = (value >= range_start[i]) & (value <= range_end[i]);
        end
    endgenerate
    
    // 优化的优先级编码器
    assign next_range_id = range_match[0] ? 3'd0 :
                          range_match[1] ? 3'd1 :
                          range_match[2] ? 3'd2 :
                          range_match[3] ? 3'd3 : 3'd0;
                          
    assign next_valid = |range_match;
    
    // 寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            range_id <= 3'd0;
            valid <= 1'b0;
        end else begin
            range_id <= next_range_id;
            valid <= next_valid;
        end
    end

endmodule