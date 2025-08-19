//SystemVerilog
module param_rom #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    output wire ready_out,
    input wire [ADDR_WIDTH-1:0] addr_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out
);

    reg [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [DATA_WIDTH-1:0] data_stage1;
    reg valid_stage1;
    reg valid_stage2;

    initial begin
        rom[0] = 8'h12;
        rom[1] = 8'h34;
        rom[2] = 8'h56;
        rom[3] = 8'h78;
    end

    assign ready_out = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            data_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            addr_stage1 <= addr_in;
            data_stage1 <= rom[addr_in];
            valid_stage1 <= valid_in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
            valid_out <= 0;
        end else begin
            data_out <= data_stage1;
            valid_out <= valid_stage1;
        end
    end

endmodule