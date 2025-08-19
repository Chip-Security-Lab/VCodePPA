module matrix_transpose #(parameter DW=8, ROWS=4, COLS=4) (
    input clk, en,
    input [DW*ROWS-1:0] row_in,
    output [DW*COLS-1:0] col_out
);
    reg [DW-1:0] matrix [0:ROWS-1][0:COLS-1];
    reg [$clog2(COLS):0] j;  // 添加j寄存器定义
    integer i;

    initial begin
        j = 0;  // 初始化j
    end

    always @(posedge clk) begin
        if(en) begin
            for(i=0; i<ROWS; i=i+1) begin
                matrix[i][j] <= row_in[i*DW +: DW];
            end
            j <= (j == COLS-1) ? 0 : j + 1;
        end
    end

    // 修复输出赋值，提取列
    genvar c;
    generate
        for(c=0; c<COLS; c=c+1) begin: col_gen
            assign col_out[c*DW +: DW] = matrix[0][c];  // 只提取第一行
        end
    endgenerate
endmodule