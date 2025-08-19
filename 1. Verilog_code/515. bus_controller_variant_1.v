module booth_multiplier(
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] result
);
    reg [8:0] booth_enc;
    reg [15:0] partial_product;
    reg [15:0] acc;
    integer i;
    
    always @(*) begin
        acc = 16'b0;
        booth_enc = {b, 1'b0};
        
        for (i = 0; i < 8; i = i + 1) begin
            case (booth_enc[2:0])
                3'b000, 3'b111: partial_product = 16'b0;
                3'b001, 3'b010: partial_product = {8'b0, a};
                3'b011: partial_product = {7'b0, a, 1'b0};
                3'b100: partial_product = -{7'b0, a, 1'b0};
                3'b101, 3'b110: partial_product = -{8'b0, a};
            endcase
            
            acc = acc + (partial_product << i);
            booth_enc = booth_enc >> 1;
        end
        
        result = acc;
    end
endmodule

module bus_controller(
    inout [7:0] bus,
    input dir,  // 方向控制
    input [7:0] tx_data,
    output [7:0] rx_data,
    input [7:0] mult_a,  // 乘法器输入A
    input [7:0] mult_b,  // 乘法器输入B
    output [15:0] mult_result  // 乘法器结果
);
    reg [7:0] bus_reg;
    
    // 实例化Booth乘法器
    booth_multiplier booth_mult_inst(
        .a(mult_a),
        .b(mult_b),
        .result(mult_result)
    );
    
    always @(*) begin
        if (dir) begin
            bus_reg = tx_data;
        end else begin
            bus_reg = 8'bz;
        end
    end
    
    assign bus = bus_reg;
    assign rx_data = bus;
endmodule