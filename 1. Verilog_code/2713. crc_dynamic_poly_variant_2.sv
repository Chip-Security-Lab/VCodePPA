//SystemVerilog
module crc_dynamic_poly #(parameter WIDTH=16)(
    input clk, load_poly,
    input [WIDTH-1:0] data_in, new_poly,
    output reg [WIDTH-1:0] crc
);
    reg [WIDTH-1:0] poly_reg;
    reg [WIDTH-1:0] next_crc;
    wire [WIDTH-1:0] xor_result;
    wire [WIDTH-1:0] conditional_poly;
    
    // 条件求和减法算法实现
    assign conditional_poly = crc[WIDTH-1] ? poly_reg : {WIDTH{1'b0}};
    assign xor_result = data_in ^ conditional_poly;
    
    always @(*) begin
        next_crc = (crc << 1) ^ xor_result;
    end
    
    always @(posedge clk) begin
        if (load_poly) 
            poly_reg <= new_poly;
        else 
            crc <= next_crc;
    end
endmodule