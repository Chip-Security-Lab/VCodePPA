module rom_reconfig #(parameter DW=8, AW=5)(
    input clk,
    input wr_en,
    input [AW-1:0] wr_addr,
    input [DW-1:0] wr_data,
    input [AW-1:0] rd_addr,
    output reg [DW-1:0] rd_data
);
    // 这实际上是RAM而不是ROM
    reg [DW-1:0] storage [0:(1<<AW)-1];
    
    // 初始化为0值
    integer i;
    initial begin
        for (i = 0; i < (1<<AW); i = i + 1)
            storage[i] = {DW{1'b0}};
    end
    
    // 写入和读取逻辑
    always @(posedge clk) begin
        if(wr_en) 
            storage[wr_addr] <= wr_data;
        rd_data <= storage[rd_addr];
    end
endmodule