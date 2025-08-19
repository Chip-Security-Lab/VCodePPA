module cam_8 (
    input wire clk,
    input wire rst,         // 添加复位信号
    input wire write_en,    // 添加写入使能
    input wire [7:0] port1_data,
    input wire [7:0] port2_data,
    output reg port1_match,
    output reg port2_match
);
    reg [7:0] stored_port1, stored_port2;
    
    always @(posedge clk) begin
        if (rst) begin
            stored_port1 <= 8'b0;
            stored_port2 <= 8'b0;
            port1_match <= 1'b0;
            port2_match <= 1'b0;
        end else if (write_en) begin
            stored_port1 <= port1_data;
            stored_port2 <= port2_data;
        end else begin
            port1_match <= (stored_port1 == port1_data);
            port2_match <= (stored_port2 == port2_data);
        end
    end
endmodule