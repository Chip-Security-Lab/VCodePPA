//SystemVerilog
//-----------------------------------------------------------------------------
// 顶层模块：ROM访问控制器
//-----------------------------------------------------------------------------
module rom_case #(
    parameter DW = 8,  // 数据宽度
    parameter AW = 4   // 地址宽度
)(
    input wire clk,
    input wire [AW-1:0] addr,
    output wire [DW-1:0] data
);
    // 内部连线
    wire [DW-1:0] rom_data;
    
    // ROM存储子模块实例化
    rom_storage #(
        .DW(DW),
        .AW(AW)
    ) u_rom_storage (
        .addr(addr),
        .data(rom_data)
    );
    
    // 数据输出寄存器子模块实例化
    rom_output_reg #(
        .DW(DW)
    ) u_rom_output_reg (
        .clk(clk),
        .data_in(rom_data),
        .data_out(data)
    );
    
endmodule

//-----------------------------------------------------------------------------
// 子模块：ROM存储单元 - 纯组合逻辑实现存储功能
//-----------------------------------------------------------------------------
module rom_storage #(
    parameter DW = 8,
    parameter AW = 4
)(
    input wire [AW-1:0] addr,
    output reg [DW-1:0] data
);
    // 组合逻辑ROM实现，减少寄存器使用
    always @(*) begin
        if (addr == 4'h0) begin
            data = 8'h00;
        end else if (addr == 4'h1) begin
            data = 8'h11;
        end else if (addr == 4'h2) begin
            data = 8'h22;
        end else if (addr == 4'h3) begin
            data = 8'h33;
        end else if (addr == 4'h4) begin
            data = 8'h44;
        end else if (addr == 4'h5) begin
            data = 8'h55;
        end else if (addr == 4'h6) begin
            data = 8'h66;
        end else if (addr == 4'h7) begin
            data = 8'h77;
        end else if (addr == 4'h8) begin
            data = 8'h88;
        end else if (addr == 4'h9) begin
            data = 8'h99;
        end else if (addr == 4'hA) begin
            data = 8'hAA;
        end else if (addr == 4'hB) begin
            data = 8'hBB;
        end else if (addr == 4'hC) begin
            data = 8'hCC;
        end else if (addr == 4'hD) begin
            data = 8'hDD;
        end else if (addr == 4'hE) begin
            data = 8'hEE;
        end else if (addr == 4'hF) begin
            data = 8'hFF;
        end else begin
            data = 8'hFF;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// 子模块：输出寄存器 - 处理时序逻辑
//-----------------------------------------------------------------------------
module rom_output_reg #(
    parameter DW = 8
)(
    input wire clk,
    input wire [DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
    // 寄存状态输出以提高时序性能
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule