//SystemVerilog
module param_rom #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input [ADDR_WIDTH-1:0] addr,
    input valid_in,
    output reg [DATA_WIDTH-1:0] data,
    output reg valid_out
);

    reg [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [DATA_WIDTH-1:0] data_stage1;
    reg valid_stage1;

    // ROM initialization
    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34; rom[2] = 8'h56; rom[3] = 8'h78;
    end

    // Address latch control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
        end else begin
            addr_stage1 <= addr;
        end
    end

    // Valid signal pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 0;
        end else begin
            valid_stage1 <= valid_in;
        end
    end

    // ROM read operation
    always @(posedge clk) begin
        data_stage1 <= rom[addr_stage1];
    end

    // Data output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 0;
        end else begin
            data <= data_stage1;
        end
    end

    // Valid output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 0;
        end else begin
            valid_out <= valid_stage1;
        end
    end

endmodule