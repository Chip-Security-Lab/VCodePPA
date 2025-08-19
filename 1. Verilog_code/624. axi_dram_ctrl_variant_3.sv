//SystemVerilog
module axi_dram_ctrl #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64
)(
    input wire clk,
    input wire rst_n,
    input wire axi_awvalid,
    input wire axi_wvalid,
    input wire [ADDR_WIDTH-1:0] axi_awaddr,
    input wire [DATA_WIDTH-1:0] axi_wdata,
    output reg axi_bready,
    output reg [DATA_WIDTH-1:0] axi_rdata
);

    reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];
    reg [2:0] state;
    localparam IDLE = 3'b000;
    localparam ADDR_DECODE = 3'b001;
    localparam WRITE_STAGE1 = 3'b010;
    localparam WRITE_STAGE2 = 3'b011;
    localparam READ_STAGE1 = 3'b100;
    localparam READ_STAGE2 = 3'b101;

    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [DATA_WIDTH-1:0] wdata_stage1;
    reg [DATA_WIDTH-1:0] rdata_stage1;
    reg write_en_stage1;
    reg read_en_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            axi_bready <= 0;
            axi_rdata <= 0;
            addr_stage1 <= 0;
            wdata_stage1 <= 0;
            rdata_stage1 <= 0;
            write_en_stage1 <= 0;
            read_en_stage1 <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (axi_awvalid && axi_wvalid) begin
                        state <= ADDR_DECODE;
                        addr_stage1 <= axi_awaddr;
                        wdata_stage1 <= axi_wdata;
                        write_en_stage1 <= 1;
                        read_en_stage1 <= 0;
                    end else begin
                        state <= ADDR_DECODE;
                        addr_stage1 <= axi_awaddr;
                        read_en_stage1 <= 1;
                        write_en_stage1 <= 0;
                    end
                end

                ADDR_DECODE: begin
                    if (write_en_stage1) begin
                        state <= WRITE_STAGE1;
                    end else begin
                        state <= READ_STAGE1;
                    end
                end

                WRITE_STAGE1: begin
                    memory[addr_stage1] <= wdata_stage1;
                    state <= WRITE_STAGE2;
                end

                WRITE_STAGE2: begin
                    state <= IDLE;
                    axi_bready <= 1;
                end

                READ_STAGE1: begin
                    rdata_stage1 <= memory[addr_stage1];
                    state <= READ_STAGE2;
                end

                READ_STAGE2: begin
                    state <= IDLE;
                    axi_rdata <= rdata_stage1;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule