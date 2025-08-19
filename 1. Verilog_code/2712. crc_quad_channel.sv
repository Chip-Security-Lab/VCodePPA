module crc_quad_channel (
    input clk, [3:0] en,
    input [7:0] data [0:3],
    output [15:0] crc [0:3]
);
    // 实现缺失的crc_channel模块
    genvar i;
    generate
        for (i=0; i<4; i=i+1) begin : channel
            // 简化的8到16 CRC模块
            crc_simple_channel inst (
                .clk(clk),
                .en(en[i]),
                .data(data[i]),
                .crc(crc[i])
            );
        end
    endgenerate
endmodule

// 添加缺失的crc_channel模块
module crc_simple_channel #(parameter WIDTH=8)(
    input clk,
    input en,
    input [WIDTH-1:0] data,
    output reg [15:0] crc
);
    parameter POLY = 16'h8005;
    
    always @(posedge clk) begin
        if (en) begin
            // 简化CRC计算
            crc <= {crc[14:0], 1'b0} ^ (crc[15] ? POLY : 16'h0000) ^ {8'h00, data};
        end
    end
endmodule