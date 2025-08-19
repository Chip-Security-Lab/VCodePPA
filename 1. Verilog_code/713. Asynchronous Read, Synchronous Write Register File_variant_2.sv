//SystemVerilog
module async_read_regfile #(
    parameter DW = 64,             // Data width
    parameter AW = 6,              // Address width
    parameter SIZE = (1 << AW)     // Register file size
)(
    input  wire           clock,
    input  wire           wr_en,
    input  wire [AW-1:0]  wr_addr,
    input  wire [DW-1:0]  wr_data,
    input  wire [AW-1:0]  rd_addr,
    output wire [DW-1:0]  rd_data
);

    // Storage element using distributed RAM
    (* ram_style = "distributed" *) reg [DW-1:0] registers [0:SIZE-1];
    
    // Read operation with registered output
    reg [DW-1:0] rd_data_reg;
    always @(posedge clock) begin
        rd_data_reg <= registers[rd_addr];
    end
    assign rd_data = rd_data_reg;
    
    // Write operation with write enable
    always @(posedge clock) begin
        if (wr_en) begin
            registers[wr_addr] <= wr_data;
        end
    end

endmodule