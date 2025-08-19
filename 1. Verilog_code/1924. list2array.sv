module list2array #(parameter DW=8, MAX_LEN=8) (
    input clk, rst_n,
    input [DW-1:0] node_data,
    input node_valid,
    output [DW*MAX_LEN-1:0] array_out,
    output reg [3:0] length
);
    reg [DW-1:0] mem [0:MAX_LEN-1];
    reg [3:0] idx;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            idx <= 0;
            length <= 0;
            for (i = 0; i < MAX_LEN; i = i + 1) begin
                mem[i] <= 0;
            end
        end else if (node_valid) begin
            mem[idx] <= node_data;
            idx <= (idx == MAX_LEN-1) ? 0 : idx + 1;
            length <= (length == MAX_LEN) ? MAX_LEN : length + 1;
        end
    end

    // 将内存连接到输出数组
    genvar g;
    generate
        for (g = 0; g < MAX_LEN; g = g + 1) begin: mem_to_array
            assign array_out[g*DW +: DW] = mem[g];
        end
    endgenerate
endmodule