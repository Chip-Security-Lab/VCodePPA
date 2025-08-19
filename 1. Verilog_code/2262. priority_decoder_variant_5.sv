//SystemVerilog
//IEEE 1364-2005 Verilog
module priority_decoder(
    input [7:0] req_in,
    output reg [2:0] grant_addr,
    output reg valid
);
    
    // 检测是否有有效请求并设置valid信号
    always @(*) begin
        valid = |req_in;
    end
    
    // 单独处理地址编码逻辑
    always @(*) begin
        if (req_in[7])
            grant_addr = 3'b111;
        else if (req_in[6])
            grant_addr = 3'b110;
        else if (req_in[5])
            grant_addr = 3'b101;
        else if (req_in[4])
            grant_addr = 3'b100;
        else if (req_in[3])
            grant_addr = 3'b011;
        else if (req_in[2])
            grant_addr = 3'b010;
        else if (req_in[1])
            grant_addr = 3'b001;
        else
            grant_addr = 3'b000;
    end
    
endmodule