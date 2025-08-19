//SystemVerilog
module sync_single_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [ADDR_WIDTH-1:0] addr_stage1, addr_stage2;
    reg we_stage1, we_stage2;
    reg [DATA_WIDTH-1:0] din_stage1, din_stage2;
    reg [DATA_WIDTH-1:0] dout_stage1, dout_stage2;
    reg valid_stage1, valid_stage2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_stage1 <= 0;
            we_stage1 <= 0;
            din_stage1 <= 0;
            valid_stage1 <= 0;
            addr_stage2 <= 0;
            we_stage2 <= 0;
            din_stage2 <= 0;
            dout_stage2 <= 0;
            valid_stage2 <= 0;
            dout <= 0;
        end else begin
            // Stage 1
            addr_stage1 <= addr;
            we_stage1 <= we;
            din_stage1 <= din;
            valid_stage1 <= 1;

            // Stage 2
            if (valid_stage1) begin
                addr_stage2 <= addr_stage1;
                we_stage2 <= we_stage1;
                din_stage2 <= din_stage1;
                valid_stage2 <= 1;
                
                if (we_stage1) begin
                    ram[addr_stage1] <= din_stage1;
                    dout_stage2 <= din_stage1;
                end else begin
                    dout_stage2 <= ram[addr_stage1];
                end
            end else begin
                valid_stage2 <= 0;
            end

            // Output stage
            if (valid_stage2) begin
                dout <= dout_stage2;
            end
        end
    end

endmodule