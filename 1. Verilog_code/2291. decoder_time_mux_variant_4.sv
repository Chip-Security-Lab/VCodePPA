//SystemVerilog
module decoder_time_mux #(parameter TS_BITS=2) (
    input clk, rst_n,
    input [7:0] addr,
    output reg [3:0] decoded
);
    // 后向寄存器重定时优化
    reg [TS_BITS-1:0] time_slot;
    reg [7:0] addr_reg; // 添加输入寄存器用于预存储addr值
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            time_slot <= 0;
            addr_reg <= 0;
        end else begin
            time_slot <= time_slot + 1;
            addr_reg <= addr; // 缓存输入地址
        end
    end
    
    // 将输出寄存器逻辑从时序逻辑中分离出来
    // 优化关键路径：减少了addr到decoded之间的组合逻辑延迟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded <= 0;
        end else begin
            decoded <= addr_reg[time_slot*4 +:4];
        end
    end
endmodule