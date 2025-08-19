//SystemVerilog
//IEEE 1364-2005 Verilog
// 顶层模块
module decoder_time_mux #(
    parameter TS_BITS = 2
)(
    input wire clk,
    input wire rst_n,
    input wire [7:0] addr,
    output wire [3:0] decoded
);

    // 内部连线
    wire [TS_BITS-1:0] time_slot;
    
    // 时间槽计数器子模块实例化
    time_slot_counter #(
        .TS_BITS(TS_BITS)
    ) time_slot_counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .time_slot(time_slot)
    );
    
    // 地址解码器子模块实例化
    address_decoder #(
        .TS_BITS(TS_BITS)
    ) address_decoder_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .time_slot(time_slot),
        .decoded(decoded)
    );

endmodule

// 时间槽计数器子模块 - 优化版本
module time_slot_counter #(
    parameter TS_BITS = 2
)(
    input wire clk,
    input wire rst_n,
    output reg [TS_BITS-1:0] time_slot
);

    // 计数器逻辑 - 使用异步复位同步使能
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            time_slot <= {TS_BITS{1'b0}};
        end else begin
            // 直接使用自增运算，对于小位宽计数器更高效
            time_slot <= time_slot + 1'b1;
        end
    end

endmodule

// 地址解码器子模块 - 后向寄存器重定时优化版本
module address_decoder #(
    parameter TS_BITS = 2
)(
    input wire clk,
    input wire rst_n,
    input wire [7:0] addr,
    input wire [TS_BITS-1:0] time_slot,
    output reg [3:0] decoded
);

    // 寄存输入，提高时序性能
    reg [7:0] addr_reg;
    reg [TS_BITS-1:0] time_slot_reg;
    
    // 直接从组合逻辑输出驱动decoded输出（移除了decoded_next和最后的寄存阶段）
    
    // 预解码寄存器 - 为后向重定时添加的新寄存器
    reg [3:0] lo_nibble_reg;
    reg [3:0] hi_nibble_reg;
    
    // 寄存输入阶段 - 并且预先解码输入数据的低位和高位部分
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg <= 8'h0;
            time_slot_reg <= {TS_BITS{1'b0}};
            // 预解码寄存器复位
            lo_nibble_reg <= 4'b0000;
            hi_nibble_reg <= 4'b0000;
        end else begin
            addr_reg <= addr;
            time_slot_reg <= time_slot;
            // 预先解码并寄存可能用到的数据部分，将组合逻辑移到寄存器前面
            lo_nibble_reg <= addr[3:0];
            hi_nibble_reg <= addr[7:4]; 
        end
    end
    
    // 后向重定时后的组合逻辑 - 从预解码的寄存器中选择
    // 时序输出逻辑被移除，改为直接组合逻辑输出，实现后向重定时
    generate
        if (TS_BITS == 2) begin: gen_ts_2
            // 使用case语句提高表达效率和可读性
            always @(*) begin
                case(time_slot_reg)
                    2'b00: decoded = lo_nibble_reg;
                    2'b01: decoded = hi_nibble_reg;
                    2'b10: decoded = lo_nibble_reg;
                    2'b11: decoded = hi_nibble_reg;
                    default: decoded = lo_nibble_reg;
                endcase
            end
        end else begin: gen_generic
            // 通用情况下根据时间槽选择预解码的数据
            always @(*) begin
                if (time_slot_reg[0] == 1'b0)
                    decoded = lo_nibble_reg;
                else
                    decoded = hi_nibble_reg;
            end
        end
    endgenerate

endmodule