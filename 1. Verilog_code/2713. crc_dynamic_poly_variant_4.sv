//SystemVerilog
module crc_dynamic_poly #(parameter WIDTH=16)(
    input wire clk, 
    input wire load_poly,
    input wire [WIDTH-1:0] data_in, 
    input wire [WIDTH-1:0] new_poly,
    output reg [WIDTH-1:0] crc
);
    reg [WIDTH-1:0] poly_reg;
    wire [WIDTH-1:0] feedback;
    wire [WIDTH-1:0] shifted_crc;
    
    // 计算移位CRC值
    assign shifted_crc = crc << 1;
    
    // 生成反馈值 - 简化为直接条件赋值
    assign feedback = crc[WIDTH-1] ? poly_reg : 'b0;
    
    // 多项式寄存器更新逻辑
    always @(posedge clk) begin
        if (load_poly) 
            poly_reg <= new_poly;
    end
    
    // CRC计算逻辑 
    always @(posedge clk) begin
        if (load_poly)
            crc <= 'b0; // 加载新多项式时重置CRC
        else 
            crc <= shifted_crc ^ (data_in ^ feedback);
    end
endmodule