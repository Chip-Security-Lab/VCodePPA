//SystemVerilog
module rom_cascadable #(parameter STAGES=3)(
    input [7:0] addr,
    output [23:0] data
);
    wire [7:0] stage_out [0:STAGES];
    assign stage_out[0] = addr;
    
    genvar i;
    generate
        for(i=0; i<STAGES; i=i+1) begin : stage
            rom_async_barrel #(8,8) u_rom(
                .a(stage_out[i]),
                .dout(stage_out[i+1])
            );
        end
    endgenerate
    
    assign data = {stage_out[1], stage_out[2], stage_out[3]};
endmodule

module rom_async_barrel #(parameter AW=8, parameter DW=8)(
    input [AW-1:0] a,
    output [DW-1:0] dout
);
    // 使用桶形移位器结构实现ROM查找
    reg [DW-1:0] barrel_rom [0:3]; // 减少存储深度以使用桶形移位器
    wire [1:0] barrel_select = a[1:0];
    wire [AW-3:0] base_addr = a[AW-1:2];
    wire [DW-1:0] barrel_out;
    
    // 初始化桶形移位器ROM
    integer i;
    initial begin
        for (i = 0; i < 4; i = i + 1)
            barrel_rom[i] = i & {DW{1'b1}};
    end
    
    // 实现桶形移位器
    wire [DW-1:0] level0 [0:3];
    wire [DW-1:0] level1 [0:1];
    
    // 第一级MUX - 4选2
    assign level0[0] = barrel_rom[0];
    assign level0[1] = barrel_rom[1];
    assign level0[2] = barrel_rom[2];
    assign level0[3] = barrel_rom[3];
    
    // 第二级MUX - 2选1
    assign level1[0] = barrel_select[0] ? level0[1] : level0[0];
    assign level1[1] = barrel_select[0] ? level0[3] : level0[2];
    
    // 第三级MUX - 最终输出
    assign barrel_out = barrel_select[1] ? level1[1] : level1[0];
    
    // 最终查找逻辑 - 组合基地址和桶形移位输出
    reg [DW-1:0] full_mem [0:(1<<(AW-2))-1];
    
    initial begin
        for (i = 0; i < (1<<(AW-2)); i = i + 1) begin
            full_mem[i] = ((i << 2) | (barrel_out & 3)) & {DW{1'b1}};
        end
    end
    
    assign dout = full_mem[base_addr];
endmodule