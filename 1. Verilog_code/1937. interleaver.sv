module interleaver #(parameter DW=8, ROWS=4, COLS=4) (
    input [ROWS*COLS*DW-1:0] data_in,
    output [ROWS*COLS*DW-1:0] data_out
);
    generate
        for(genvar r=0; r<ROWS; r=r+1) begin: row_gen  // 添加命名的generate块
            for(genvar c=0; c<COLS; c=c+1) begin: col_gen
                assign data_out[(c*ROWS + r)*DW +: DW] = 
                       data_in[(r*COLS + c)*DW +: DW];
            end
        end
    endgenerate
endmodule