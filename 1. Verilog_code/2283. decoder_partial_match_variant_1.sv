//SystemVerilog
// 顶层模块
module decoder_partial_match #(
    parameter MASK = 4'hF
) (
    input  [3:0] addr_in,
    output [7:0] device_sel
);
    wire [3:0] masked_addr;
    wire       match_flag;
    
    // 子模块实例化
    address_masking #(
        .MASK(MASK)
    ) masking_unit (
        .addr_in    (addr_in),
        .masked_addr(masked_addr)
    );
    
    pattern_matching #(
        .PATTERN(4'hA)
    ) matching_unit (
        .masked_addr(masked_addr),
        .match_flag (match_flag)
    );
    
    output_generator output_unit (
        .match_flag (match_flag),
        .device_sel (device_sel)
    );
    
endmodule

// 子模块1: 地址掩码单元
module address_masking #(
    parameter MASK = 4'hF
) (
    input  [3:0] addr_in,
    output [3:0] masked_addr
);
    assign masked_addr = addr_in & MASK;
endmodule

// 子模块2: 模式匹配单元
module pattern_matching #(
    parameter PATTERN = 4'hA
) (
    input  [3:0] masked_addr,
    output       match_flag
);
    assign match_flag = (masked_addr == PATTERN);
endmodule

// 子模块3: 输出生成单元
module output_generator (
    input        match_flag,
    output reg [7:0] device_sel
);
    always @(*) begin
        if (match_flag) begin
            device_sel = 8'h01;
        end
        else begin
            device_sel = 8'h00;
        end
    end
endmodule