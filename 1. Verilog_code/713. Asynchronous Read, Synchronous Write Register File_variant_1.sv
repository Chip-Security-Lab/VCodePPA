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

    // Internal signals
    wire [AW-1:0] rd_addr_pipe;
    wire [DW-1:0] rd_data_pipe;

    // Address pipeline stage
    addr_pipeline #(
        .AW(AW)
    ) addr_pipe (
        .clock(clock),
        .rd_addr_in(rd_addr),
        .rd_addr_out(rd_addr_pipe)
    );

    // Register file storage
    regfile_storage #(
        .DW(DW),
        .AW(AW),
        .SIZE(SIZE)
    ) storage (
        .clock(clock),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_addr(rd_addr_pipe),
        .rd_data(rd_data_pipe)
    );

    // Data pipeline stage
    data_pipeline #(
        .DW(DW)
    ) data_pipe (
        .clock(clock),
        .rd_data_in(rd_data_pipe),
        .rd_data_out(rd_data)
    );

endmodule

// Address pipeline module
module addr_pipeline #(
    parameter AW = 6
)(
    input  wire           clock,
    input  wire [AW-1:0]  rd_addr_in,
    output wire [AW-1:0]  rd_addr_out
);
    reg [AW-1:0] addr_reg;
    
    always @(posedge clock) begin
        addr_reg <= rd_addr_in;
    end
    
    assign rd_addr_out = addr_reg;
endmodule

// Register file storage module
module regfile_storage #(
    parameter DW = 64,
    parameter AW = 6,
    parameter SIZE = (1 << AW)
)(
    input  wire           clock,
    input  wire           wr_en,
    input  wire [AW-1:0]  wr_addr,
    input  wire [DW-1:0]  wr_data,
    input  wire [AW-1:0]  rd_addr,
    output wire [DW-1:0]  rd_data
);
    reg [DW-1:0] registers [0:SIZE-1];
    
    // Read operation
    assign rd_data = registers[rd_addr];
    
    // Write operation
    always @(posedge clock) begin
        if (wr_en) begin
            registers[wr_addr] <= wr_data;
        end
    end
endmodule

// Data pipeline module
module data_pipeline #(
    parameter DW = 64
)(
    input  wire           clock,
    input  wire [DW-1:0]  rd_data_in,
    output wire [DW-1:0]  rd_data_out
);
    reg [DW-1:0] data_reg;
    
    always @(posedge clock) begin
        data_reg <= rd_data_in;
    end
    
    assign rd_data_out = data_reg;
endmodule