//SystemVerilog
module hybrid_regfile #(
    parameter TRIGGER_DEPTH = 8,
    parameter RAM_DEPTH = 24
)(
    input clk,
    input wr_en,
    input [7:0] addr,
    input [31:0] din,
    output [31:0] dout
);
    // 低地址使用触发器
    reg [31:0] trigger_bank [0:TRIGGER_DEPTH-1];

    // 高地址使用RAM（行为级模型）
    reg [31:0] ram_bank [TRIGGER_DEPTH:TRIGGER_DEPTH+RAM_DEPTH-1];
    
    // 地址类型信号 - 使用显式比较
    wire addr_in_trigger_range = (addr < TRIGGER_DEPTH);
    wire addr_in_ram_range = (addr >= TRIGGER_DEPTH) && (addr < TRIGGER_DEPTH+RAM_DEPTH);
    
    // 写入逻辑 - 使用显式多路复用器结构
    always @(posedge clk) begin
        if (wr_en) begin
            if (addr_in_trigger_range) begin
                trigger_bank[addr] <= din;
            end
            else if (addr_in_ram_range) begin
                ram_bank[addr] <= din;
            end
        end
    end

    // 读取逻辑 - 使用显式多路复用器结构
    reg [31:0] trigger_out;
    reg [31:0] ram_out;
    
    always @(*) begin
        trigger_out = addr_in_trigger_range ? trigger_bank[addr] : 32'h0;
        ram_out = addr_in_ram_range ? ram_bank[addr] : 32'h0;
    end
    
    // 输出多路复用器
    assign dout = addr_in_trigger_range ? trigger_out : ram_out;
endmodule