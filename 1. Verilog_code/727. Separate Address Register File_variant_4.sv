//SystemVerilog
module separate_addr_regfile #(
    parameter DATA_W = 32,
    parameter WR_ADDR_W = 4,
    parameter RD_ADDR_W = 5
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  wr_en,
    input  wire [WR_ADDR_W-1:0]  wr_addr,
    input  wire [DATA_W-1:0]     wr_data,
    input  wire [RD_ADDR_W-1:0]  rd_addr,
    output wire [DATA_W-1:0]     rd_data
);

    // Address extension module
    wire [RD_ADDR_W-1:0] extended_wr_addr;
    addr_extension #(
        .WR_ADDR_W(WR_ADDR_W),
        .RD_ADDR_W(RD_ADDR_W)
    ) addr_ext (
        .wr_addr(wr_addr),
        .extended_wr_addr(extended_wr_addr)
    );

    // Register file core
    regfile_core #(
        .DATA_W(DATA_W),
        .ADDR_W(RD_ADDR_W)
    ) regfile (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .wr_addr(extended_wr_addr),
        .wr_data(wr_data),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

endmodule

module addr_extension #(
    parameter WR_ADDR_W = 4,
    parameter RD_ADDR_W = 5
)(
    input  wire [WR_ADDR_W-1:0]  wr_addr,
    output wire [RD_ADDR_W-1:0]  extended_wr_addr
);
    assign extended_wr_addr = {{(RD_ADDR_W-WR_ADDR_W){1'b0}}, wr_addr};
endmodule

module regfile_core #(
    parameter DATA_W = 32,
    parameter ADDR_W = 5
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  wr_en,
    input  wire [ADDR_W-1:0]     wr_addr,
    input  wire [DATA_W-1:0]     wr_data,
    input  wire [ADDR_W-1:0]     rd_addr,
    output wire [DATA_W-1:0]     rd_data
);
    reg [DATA_W-1:0] registers [0:(2**ADDR_W)-1];
    
    assign rd_data = registers[rd_addr];
    
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < (2**ADDR_W); i = i + 1) begin
                registers[i] <= {DATA_W{1'b0}};
            end
        end
        else if (wr_en) begin
            registers[wr_addr] <= wr_data;
        end
    end
endmodule

module subtractor #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] result
);
    assign result = a + (~b + 1'b1); // Two's complement subtraction
endmodule