//SystemVerilog
module shift_queue #(parameter DW=8, DEPTH=4) (
    input wire clk,
    input wire load,
    input wire shift,
    input wire [DW*DEPTH-1:0] data_in,
    output reg [DW-1:0] data_out
);
    reg [DW-1:0] queue [0:DEPTH-1];
    integer idx;

    // 简化布尔表达式
    wire load_en  = load & ~shift;
    wire shift_en = shift & ~load;

    // 优化路径：预解码data_in为数组，减少数据重组深度
    wire [DW-1:0] data_in_array [0:DEPTH-1];
    genvar gi;
    generate
        for (gi = 0; gi < DEPTH; gi = gi + 1) begin : DATA_IN_DECODE
            assign data_in_array[gi] = data_in[gi*DW +: DW];
        end
    endgenerate

    always @(posedge clk) begin
        if (load_en) begin
            for (idx = 0; idx < DEPTH; idx = idx + 1) begin
                queue[idx] <= data_in_array[idx];
            end
            data_out <= data_in_array[DEPTH-1];
        end else if (shift_en) begin
            for (idx = DEPTH-1; idx > 0; idx = idx - 1) begin
                queue[idx] <= queue[idx-1];
            end
            queue[0] <= {DW{1'b0}};
            data_out <= queue[DEPTH-1];
        end
    end

endmodule