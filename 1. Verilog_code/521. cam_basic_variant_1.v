module cam_basic #(parameter WIDTH=8, DEPTH=16)(
    input clk,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] data_in,
    output reg [DEPTH-1:0] match_flags
);
    reg [WIDTH-1:0] cam_table [0:DEPTH-1];
    reg [WIDTH-1:0] data_in_reg;
    integer j;
    
    // 写入逻辑
    always @(posedge clk) begin
        if (write_en)
            cam_table[write_addr] <= write_data;
        data_in_reg <= data_in;
    end
    
    // 并行比较逻辑
    always @(posedge clk) begin
        j = 0;
        while (j < DEPTH) begin
            match_flags[j] <= (cam_table[j] == data_in_reg);
            j = j + 1;
        end
    end
endmodule