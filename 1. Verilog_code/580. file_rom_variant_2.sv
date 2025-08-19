//SystemVerilog
module file_rom (
    input clk,
    input [3:0] addr,
    input req,
    output reg ack,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];
    reg req_dly1, req_dly2;
    reg [3:0] addr_stage1;
    reg [7:0] data_stage1;
    reg ack_stage1;

    initial begin
        $readmemh("rom_data.hex", rom);
    end

    // Stage 1: Address and request processing
    always @(posedge clk) begin
        req_dly1 <= req;
        addr_stage1 <= addr;
    end

    // Stage 2: ROM access and data preparation
    always @(posedge clk) begin
        req_dly2 <= req_dly1;
        if (req_dly1 && !req_dly2) begin
            data_stage1 <= rom[addr_stage1];
            ack_stage1 <= 1'b1;
        end else if (!req_dly1) begin
            ack_stage1 <= 1'b0;
        end
    end

    // Stage 3: Output registration
    always @(posedge clk) begin
        data <= data_stage1;
        ack <= ack_stage1;
    end

endmodule