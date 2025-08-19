//SystemVerilog
module cam_8 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [7:0] port1_data,
    input wire [7:0] port2_data,
    output reg port1_match,
    output reg port2_match
);
    reg [7:0] stored_port1, stored_port2;
    wire port1_match_next, port2_match_next;
    
    // 预计算比较结果
    assign port1_match_next = (stored_port1 == port1_data);
    assign port2_match_next = (stored_port2 == port2_data);
    
    always @(posedge clk) begin
        if (rst) begin
            stored_port1 <= 8'b0;
            stored_port2 <= 8'b0;
            port1_match <= 1'b0;
            port2_match <= 1'b0;
        end else if (write_en) begin
            stored_port1 <= port1_data;
            stored_port2 <= port2_data;
            port1_match <= 1'b0;
            port2_match <= 1'b0;
        end else begin
            port1_match <= port1_match_next;
            port2_match <= port2_match_next;
        end
    end
endmodule