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
    wire [DEPTH-1:0] match_flags_next;
    
    // 写入逻辑
    always @(posedge clk) begin
        if (write_en)
            cam_table[write_addr] <= write_data;
        data_in_reg <= data_in;
    end
    
    // 优化后的并行比较逻辑
    genvar i;
    generate
        for(i=0; i<DEPTH; i=i+1) begin: COMPARE
            assign match_flags_next[i] = (cam_table[i] == data_in_reg);
        end
    endgenerate
    
    // 寄存器输出
    always @(posedge clk) begin
        match_flags <= match_flags_next;
    end
endmodule