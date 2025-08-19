module prio_queue #(parameter DW=8, SIZE=4) (
    input [DW*SIZE-1:0] data_in,
    output [DW-1:0] data_out
);
    // 修复错误的数组赋值
    wire [DW-1:0] entries [0:SIZE-1];
    
    // 将data_in分割为单独的项
    genvar i;
    generate
        for (i = 0; i < SIZE; i = i + 1) begin: entry_split
            assign entries[i] = data_in[(i+1)*DW-1:i*DW];
        end
    endgenerate
    
    // 优先级逻辑
    assign data_out = (|entries[3]) ? entries[3] : 
                     (|entries[2]) ? entries[2] :
                     (|entries[1]) ? entries[1] : entries[0];
endmodule