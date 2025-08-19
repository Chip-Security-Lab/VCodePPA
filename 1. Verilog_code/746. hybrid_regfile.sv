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

always @(posedge clk) begin
    if (wr_en) begin
        if (addr < TRIGGER_DEPTH)
            trigger_bank[addr] <= din;
        else if (addr < TRIGGER_DEPTH+RAM_DEPTH)
            ram_bank[addr] <= din;
    end
end

assign dout = (addr < TRIGGER_DEPTH) ? 
              trigger_bank[addr] : 
              ram_bank[addr];
endmodule