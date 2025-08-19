//SystemVerilog
module crc_dual_clock (
    input clk_a, clk_b, rst,
    input [7:0] data_a,
    input valid_a,
    output reg ready_a,
    output reg [15:0] crc_b
);

reg [7:0] data_sync;
reg [15:0] crc_reg;
reg valid_sync;
reg ready_sync;

// 输入域同步
always @(posedge clk_a) begin
    if (rst) begin
        data_sync <= 8'h00;
        valid_sync <= 1'b0;
        ready_a <= 1'b1;
    end else begin
        if (valid_a && ready_a) begin
            data_sync <= data_a;
            valid_sync <= 1'b1;
            ready_a <= 1'b0;
        end else if (ready_sync) begin
            valid_sync <= 1'b0;
            ready_a <= 1'b1;
        end
    end
end

// 计算域
always @(posedge clk_b) begin
    if (rst) begin
        crc_reg <= 16'hFFFF;
        ready_sync <= 1'b0;
    end else begin
        if (valid_sync && !ready_sync) begin
            crc_reg <= {crc_reg[14:0], 1'b0} ^ 
                      (crc_reg[15] ? 16'h8005 : 0) ^
                      {8'h00, data_sync};
            ready_sync <= 1'b1;
        end else if (ready_sync && !valid_sync) begin
            ready_sync <= 1'b0;
        end
    end
    crc_b <= crc_reg;
end

endmodule