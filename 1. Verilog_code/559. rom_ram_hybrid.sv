module rom_ram_hybrid #(parameter MODE=0)(
    input clk,
    input [7:0] addr,
    input [15:0] din,
    input rst,          // 添加复位信号
    output [15:0] dout
);
    reg [15:0] mem [0:255];
    
    // 初始化为0
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 16'h0000;
    end
    
    // 读取逻辑
    assign dout = mem[addr];
    
    // 写入逻辑
    generate
        if(MODE == 1) begin
            always @(posedge clk) begin
                if (rst) begin
                    for (i = 0; i < 256; i = i + 1)
                        mem[i] <= 16'h0000;
                end else begin
                    mem[addr] <= din;
                end
            end
        end
    endgenerate
endmodule