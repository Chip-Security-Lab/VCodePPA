//SystemVerilog
module sync_priority_single_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] data_stage1;
    reg [DATA_WIDTH-1:0] data_stage2;
    reg valid_stage1;
    reg valid_stage2;
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [ADDR_WIDTH-1:0] addr_stage2;
    reg we_stage1;
    reg we_stage2;
    
    wire write_enable;
    wire [ADDR_WIDTH-1:0] write_addr;
    wire [DATA_WIDTH-1:0] write_data;
    
    assign write_enable = we_a | we_b;
    assign write_addr = we_a ? addr_a : addr_b;
    assign write_data = we_a ? din_a : din_b;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_stage1 <= 0;
            valid_stage1 <= 0;
            addr_stage1 <= 0;
            we_stage1 <= 0;
        end else begin
            if (write_enable) begin
                ram[write_addr] <= write_data;
                data_stage1 <= write_data;
                valid_stage1 <= 1'b1;
                addr_stage1 <= write_addr;
                we_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
                we_stage1 <= 1'b0;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_stage2 <= 0;
            valid_stage2 <= 0;
            addr_stage2 <= 0;
            we_stage2 <= 0;
        end else begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
            addr_stage2 <= addr_stage1;
            we_stage2 <= we_stage1;
        end
    end

    wire [DATA_WIDTH-1:0] ram_data;
    assign ram_data = ram[addr_stage2];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else begin
            dout <= (valid_stage2 & we_stage2) ? data_stage2 : ram_data;
        end
    end

endmodule