//SystemVerilog
module hybrid_regfile #(
    parameter TRIGGER_DEPTH = 8,
    parameter RAM_DEPTH = 24
)(
    input clk,
    input wr_en,
    input [7:0] addr,
    input [31:0] din,
    output reg [31:0] dout
);
    // 低地址使用触发器
    reg [31:0] trigger_bank [0:TRIGGER_DEPTH-1];
    
    // 高地址使用RAM（行为级模型）
    reg [31:0] ram_bank [0:RAM_DEPTH-1];
    
    // 地址范围判断信号
    wire is_trigger_range = (addr < TRIGGER_DEPTH);
    wire is_ram_range = (addr >= TRIGGER_DEPTH) && (addr < TRIGGER_DEPTH+RAM_DEPTH);
    
    // RAM地址映射
    wire [7:0] ram_addr = addr - TRIGGER_DEPTH;
    
    // 写逻辑优化
    always @(posedge clk) begin
        if (wr_en) begin
            case (1'b1) // 使用case语句重组控制流
                is_trigger_range: trigger_bank[addr] <= din;
                is_ram_range: ram_bank[ram_addr] <= din;
                default: ; // 不做任何操作
            endcase
        end
    end
    
    // 读逻辑优化 - 使用组合逻辑实现单周期访问
    always @(*) begin
        case (1'b1) // 使用case语句重组控制流
            is_trigger_range: dout = trigger_bank[addr];
            is_ram_range: dout = ram_bank[ram_addr];
            default: dout = 32'h0; // 默认值为0，处理地址超出范围的情况
        endcase
    end
endmodule