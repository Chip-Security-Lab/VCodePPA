//SystemVerilog
module decoder_multi_protocol (
    input clk,
    input rst_n,
    input [1:0] mode,
    input [15:0] addr,
    input valid,
    output reg ready,
    output reg [7:0] select
);

reg [7:0] select_next;
reg ready_next;

always @* begin
    case(mode)
        2'b00: begin
            if (addr[15:12] == 4'h1) begin
                select_next = 8'h01;  // I2C模式
            end else begin
                select_next = 8'h00;
            end
        end
        2'b01: begin
            if (addr[7:5] == 3'b101) begin
                select_next = 8'h02;  // SPI模式
            end else begin
                select_next = 8'h00;
            end
        end
        2'b10: begin
            if (addr[11:8] > 4'h7) begin
                select_next = 8'h04;  // AXI模式
            end else begin
                select_next = 8'h00;
            end
        end
        default: select_next = 8'h00;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        select <= 8'h00;
        ready <= 1'b0;
    end else begin
        select <= select_next;
        ready <= valid;
    end
end

endmodule